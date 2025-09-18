#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

# ====== PARAM ======
VIP_DB="10.7.0.10"
VIP_PORT="3306"

# DC1 (lokal)
MYSQL_LOCAL_CONTAINER="mysql1"
MYSQL_ROOT_PASS="abcdef"

# DC2 (remote via MySQL TCP)
REMOTE_DB_HOST="10.7.0.5"
REMOTE_DB_PORT="3306"
HA_USER="ha"
HA_PASS="HaPassw0rd!"
# set DISABLED jika di WG (lebih cepat); ganti REQUIRED jika pakai SSL MySQL
SSL_MODE="DISABLED"

# (opsional) route hub
HUB="10.7.0.1"
SSH_OPTS="-o StrictHostKeyChecking=no -q -T"   # dipakai hanya utk switch route (boleh dihapus)

# ====== HELPER ======
ts() { date '+%F %T'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG" ; }

mysql_local() {
  docker exec -i "$MYSQL_LOCAL_CONTAINER" \
    mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "$1"
}

mysql_remote() {
  # langsung TCP ke DC2 MySQL
  mysql -h"$REMOTE_DB_HOST" -P"$REMOTE_DB_PORT" \
        -u"$HA_USER" -p"$HA_PASS" --ssl-mode="$SSL_MODE" \
        --connect-timeout=3 -Nse "$1"
}

check_remote_rw() {
  mysql_remote "SELECT @@read_only;" 2>/dev/null | tr -d '\r\n' || echo "ERR"
}

promote_local_writer() {
  log "Promote DC1 ($MYSQL_LOCAL_CONTAINER) sebagai WRITER"
  mysql_local "STOP REPLICA; RESET REPLICA ALL;"
  mysql_local "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
  local ro; ro=$(mysql_local "SELECT @@read_only;")
  [[ "$ro" == "0" ]] || { log "ERROR: DC1 gagal jadi writer (read_only=$ro)"; exit 1; }
  log "OK: DC1 sekarang WRITER (read_only=0)"
}

demote_local_replica_to_vip() {
  log "Demote DC1 jadi REPLICA ke VIP ${VIP_DB}:${VIP_PORT}"
  mysql_local "SET GLOBAL super_read_only=1; SET GLOBAL read_only=1;"
  mysql_local "CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${VIP_DB}', SOURCE_PORT=${VIP_PORT},
    SOURCE_USER='rep1', SOURCE_PASSWORD='abcdef',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_local "START REPLICA;"
  local io sql
  io=$(docker exec -i "$MYSQL_LOCAL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "SHOW REPLICA STATUS\G" | awk -F': ' '/Replica_IO_Running/ {print $2}')
  sql=$(docker exec -i "$MYSQL_LOCAL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "SHOW REPLICA STATUS\G" | awk -F': ' '/Replica_SQL_Running/ {print $2}')
  log "DC1 Replica status: IO=${io:-?}, SQL=${sql:-?}"
}

force_remote_replica_to_vip() {
  log "Paksa DC2 jadi REPLICA (RO) ke VIP ${VIP_DB}:${VIP_PORT}"
  mysql_remote "SET GLOBAL super_read_only=1; SET GLOBAL read_only=1;"
  mysql_remote "CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${VIP_DB}', SOURCE_PORT=${VIP_PORT},
    SOURCE_USER='rep1', SOURCE_PASSWORD='abcdef',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_remote "START REPLICA;"
}

force_remote_writer() {
  log "Paksa DC2 jadi WRITER (stop repl + buka write)"
  mysql_remote "STOP REPLICA; RESET REPLICA ALL;"
  mysql_remote "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
}

# ====== MAIN ======
echo "[$(ts)] DC1 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # (opsional) inform hub
    ssh $SSH_OPTS root@"$HUB" "switch-db-route.sh db1" >> "$LOG" 2>&1 || true

    # 1) Demote peer dulu (hindari dual-writer). Jika gagal, ABORT promote.
    if force_remote_replica_to_vip 2>>"$LOG"; then
      # 2) Promote lokal writer
      promote_local_writer
      # 3) Verifikasi peer benar2 RO
      remote_ro=$(check_remote_rw)
      if [[ "$remote_ro" != "1" ]]; then
        log "WARNING: verifikasi remote @@read_only=$remote_ro (harap cek manual)"
      fi
      log "Sukses MASTER handler: DC1 WRITER, DC2 REPLICA"
    else
      log "ERROR: gagal set DC2 jadi REPLICA → ABORT PROMOTE (hindari dual-writer)"
      exit 1
    fi
    ;;

  backup)
    log "DC1 BACKUP → anggap DC2 MASTER"
    # 1) Demote lokal
    demote_local_replica_to_vip || { log "Demote local gagal"; exit 1; }
    # 2) Pastikan remote writer (best-effort, tidak fatal kalau gagal)
    force_remote_writer || log "Warning: gagal paksa DC2 writer (cek manual)"
    log "Sukses BACKUP handler: DC1 REPLICA, DC2 WRITER"
    ;;

  fault)
    log "DC1 fault condition (no-op)"
    ;;

  *)
    log "Event tidak dikenal: $TYPE"
    ;;
esac
