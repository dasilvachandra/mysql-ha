#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

# ====== PARAM KONFIGURASI ======
# VIP DB bersama
VIP_DB="10.7.0.10"
VIP_PORT="3306"

# DC1 (lokal)
MYSQL_LOCAL_CONTAINER="mysql1"
MYSQL_ROOT_PASS="abcdef"

# DC2 (remote)
REMOTE_HOST="10.7.0.5"
MYSQL_REMOTE_CONTAINER="mysql2"
SSH_OPTS="-o StrictHostKeyChecking=no -q -T"

# Kredensial replika
REPL_USER="rep1"
REPL_PASS="abcdef"

# ====== HELPER ======
ts() { date '+%F %T'; }

log() { echo "[$(ts)] $*" | tee -a "$LOG" ; }

mysql_local() {
  docker exec -i "$MYSQL_LOCAL_CONTAINER" \
    mysql -uroot -p"$MYSQL_ROOT_PASS" -Nse "$1"
}

mysql_remote() {
  # jalankan perintah mysql di DC2 via ssh + docker exec
  ssh $SSH_OPTS "root@${REMOTE_HOST}" \
    "docker exec -i ${MYSQL_REMOTE_CONTAINER} mysql -uroot -p'${MYSQL_ROOT_PASS}' -Nse \"$1\""
}

promote_local_writer() {
  log "Promote DC1 ($MYSQL_LOCAL_CONTAINER) sebagai WRITER"
  # Matikan replika jika ada, buang metadata replika, lalu buka write
  mysql_local "STOP REPLICA; RESET REPLICA ALL;"
  mysql_local "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
  # Verifikasi
  local ro
  ro=$(mysql_local "SELECT @@read_only;")
  if [[ "$ro" != "0" ]]; then
    log "ERROR: DC1 gagal jadi writer (read_only=$ro)"; exit 1
  fi
  log "OK: DC1 sekarang WRITER (read_only=0)"
}

demote_local_replica_to_vip() {
  log "Demote DC1 jadi REPLICA ke VIP ${VIP_DB}:${VIP_PORT}"
  mysql_local "SET GLOBAL super_read_only=1; SET GLOBAL read_only=1;"
  mysql_local "CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${VIP_DB}', SOURCE_PORT=${VIP_PORT},
    SOURCE_USER='${REPL_USER}', SOURCE_PASSWORD='${REPL_PASS}',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_local "START REPLICA;"
  # Cek singkat
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
    SOURCE_USER='${REPL_USER}', SOURCE_PASSWORD='${REPL_PASS}',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_remote "START REPLICA;"
}

force_remote_writer() {
  log "Paksa DC2 jadi WRITER (matikan replika + buka write)"
  mysql_remote "STOP REPLICA; RESET REPLICA ALL;"
  mysql_remote "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
}

# ====== MAIN ======
echo "[$(ts)] DC1 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # 1) Arahkan route di hub → db1 (opsional, dari script kamu)
    ssh $SSH_OPTS root@10.7.0.1 "switch-db-route.sh db1" >> "$LOG" 2>&1 || true

    # 2) Promote lokal (DC1) sebagai writer
    promote_local_writer

    # 3) Paksa DC2 jadi replica ke VIP (yang sekarang nempel di DC1)
    force_remote_replica_to_vip

    log "Sukses MASTER handler: DC1 WRITER, DC2 REPLICA"
    ;;

  backup)
    log "DC1 masuk BACKUP → anggap DC2 MASTER"
    # 1) Demote lokal (DC1) jadi replica ke VIP (yang mestinya nempel di DC2)
    demote_local_replica_to_vip

    # 2) Paksa DC2 jadi writer (jaga-jaga kalau masih replica)
    force_remote_writer

    log "Sukses BACKUP handler: DC1 REPLICA, DC2 WRITER"
    ;;

  fault)
    log "DC1 fault condition (no-op di sini)"
    ;;

  *)
    log "Event tidak dikenal: $TYPE"
    ;;
esac
