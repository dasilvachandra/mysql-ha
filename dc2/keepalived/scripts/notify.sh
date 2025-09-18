#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

# ====== PARAM ======
VIP_DB="10.7.0.10"
VIP_PORT="3306"

# DC2 (lokal)
MYSQL_LOCAL_CONTAINER="mysql2"
MYSQL_ROOT_PASS="abcdef"

# DC1 (remote via MySQL TCP)
REMOTE_DB_HOST="10.7.0.4"
REMOTE_DB_PORT="3306"
HA_USER="ha"
HA_PASS="HaPassw0rd!"
SSL_MODE="DISABLED"   # pakai "REQUIRED" kalau SSL MySQL aktif

# (opsional) route hub
HUB="10.7.0.1"
SSH_OPTS="-o StrictHostKeyChecking=no -q -T"   # hanya dipakai utk switch route (boleh dihapus)

# ====== HELPER ======
ts() { date '+%F %T'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG" ; }

mysql_local() {
  docker exec -i "$MYSQL_LOCAL_CONTAINER" \
    mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "$1"
}

mysql_remote() {
  mysql -h"$REMOTE_DB_HOST" -P"$REMOTE_DB_PORT" \
        -u"$HA_USER" -p"$HA_PASS" --ssl-mode="$SSL_MODE" \
        --connect-timeout=3 -Nse "$1"
}

check_remote_rw() {
  mysql_remote "SELECT @@read_only;" 2>/dev/null | tr -d '\r\n' || echo "ERR"
}

promote_local_writer() {
  log "Promote DC2 ($MYSQL_LOCAL_CONTAINER) sebagai WRITER"
  mysql_local "STOP REPLICA; RESET REPLICA ALL;"
  mysql_local "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
  local ro; ro=$(mysql_local "SELECT @@read_only;")
  [[ "$ro" == "0" ]] || { log "ERROR: DC2 gagal jadi writer (read_only=$ro)"; exit 1; }
  log "OK: DC2 sekarang WRITER (read_only=0)"
}

demote_local_replica_to_vip() {
  log "Demote DC2 jadi REPLICA ke VIP ${VIP_DB}:${VIP_PORT}"
  mysql_local "SET GLOBAL super_read_only=1; SET GLOBAL read_only=1;"
  mysql_local "CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${VIP_DB}', SOURCE_PORT=${VIP_PORT},
    SOURCE_USER='rep1', SOURCE_PASSWORD='abcdef',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_local "START REPLICA;"
  local io sql
  io=$(docker exec -i "$MYSQL_LOCAL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "SHOW REPLICA STATUS\G" | awk -F': ' '/Replica_IO_Running/ {print $2}')
  sql=$(docker exec -i "$MYSQL_LOCAL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "SHOW REPLICA STATUS\G" | awk -F': ' '/Replica_SQL_Running/ {print $2}')
  log "DC2 Replica status: IO=${io:-?}, SQL=${sql:-?}"
}

force_remote_replica_to_vip() {
  log "Paksa DC1 jadi REPLICA (RO) ke VIP ${VIP_DB}:${VIP_PORT}"
  mysql_remote "SET GLOBAL super_read_only=1; SET GLOBAL read_only=1;"
  mysql_remote "CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${VIP_DB}', SOURCE_PORT=${VIP_PORT},
    SOURCE_USER='rep1', SOURCE_PASSWORD='abcdef',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_remote "START REPLICA;"
}

force_remote_writer() {
  log "Paksa DC1 jadi WRITER (stop repl + buka write)"
  mysql_remote "STOP REPLICA; RESET REPLICA ALL;"
  mysql_remote "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
}

# ====== MAIN ======
echo "[$(ts)] DC2 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # (opsional) ubah routing di hub ke db2
    ssh $SSH_OPTS root@"$HUB" "switch-db-route.sh db2" >> "$LOG" 2>&1 || true

    # 1) Demote peer (DC1) dulu, baru promote lokal
    if force_remote_replica_to_vip 2>>"$LOG"; then
      promote_local_writer
      remote_ro=$(check_remote_rw)
      if [[ "$remote_ro" != "1" ]]; then
        log "WARNING: verifikasi remote @@read_only=$remote_ro (harap cek manual)"
      fi
      log "Sukses MASTER handler: DC2 WRITER, DC1 REPLICA"
    else
      log "ERROR: gagal set DC1 jadi REPLICA → ABORT PROMOTE (hindari dual-writer)"
      exit 1
    fi
    ;;

  backup)
    log "DC2 BACKUP → anggap DC1 MASTER"
    demote_local_replica_to_vip || { log "Demote local gagal"; exit 1; }
    force_remote_writer || log "Warning: gagal paksa DC1 writer (cek manual)"
    log "Sukses BACKUP handler: DC2 REPLICA, DC1 WRITER"
    ;;

  fault)
    log "DC2 fault condition (no-op)"
    ;;

  *)
    log "Event tidak dikenal: $TYPE"
    ;;
esac
