#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

# ====== PARAM KONFIGURASI ======
VIP_DB="10.7.0.10"
VIP_PORT="3306"

# DC2 (lokal)
MYSQL_LOCAL_CONTAINER="mysql2"
MYSQL_ROOT_PASS="abcdef"

# DC1 (remote)
REMOTE_HOST="10.7.0.4"
MYSQL_REMOTE_CONTAINER="mysql1"
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
  ssh $SSH_OPTS "root@${REMOTE_HOST}" \
    "docker exec -i ${MYSQL_REMOTE_CONTAINER} mysql -uroot -p'${MYSQL_ROOT_PASS}' -Nse \"$1\""
}

promote_local_writer() {
  log "Promote DC2 ($MYSQL_LOCAL_CONTAINER) sebagai WRITER"
  mysql_local "STOP REPLICA; RESET REPLICA ALL;"
  mysql_local "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
  local ro
  ro=$(mysql_local "SELECT @@read_only;")
  if [[ "$ro" != "0" ]]; then
    log "ERROR: DC2 gagal jadi writer (read_only=$ro)"; exit 1
  fi
  log "OK: DC2 sekarang WRITER (read_only=0)"
}

demote_local_replica_to_vip() {
  log "Demote DC2 jadi REPLICA ke VIP ${VIP_DB}:${VIP_PORT}"
  mysql_local "SET GLOBAL super_read_only=1; SET GLOBAL read_only=1;"
  mysql_local "CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='${VIP_DB}', SOURCE_PORT=${VIP_PORT},
    SOURCE_USER='${REPL_USER}', SOURCE_PASSWORD='${REPL_PASS}',
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
    SOURCE_USER='${REPL_USER}', SOURCE_PASSWORD='${REPL_PASS}',
    SOURCE_AUTO_POSITION=1, SOURCE_SSL=1;"
  mysql_remote "START REPLICA;"
}

force_remote_writer() {
  log "Paksa DC1 jadi WRITER (matikan replika + buka write)"
  mysql_remote "STOP REPLICA; RESET REPLICA ALL;"
  mysql_remote "SET GLOBAL super_read_only=0; SET GLOBAL read_only=0;"
}

# ====== MAIN ======
echo "[$(ts)] DC2 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # (Opsional) Ubah routing di hub ke db2
    ssh $SSH_OPTS root@10.7.0.1 "switch-db-route.sh db2" >> "$LOG" 2>&1 || true

    # 1) Promote lokal (DC2) sebagai writer
    promote_local_writer

    # 2) Paksa DC1 jadi replica ke VIP (yang sekarang nempel di DC2)
    force_remote_replica_to_vip

    log "Sukses MASTER handler: DC2 WRITER, DC1 REPLICA"
    ;;

  backup)
    log "DC2 masuk BACKUP → anggap DC1 MASTER"
    # 1) Demote lokal (DC2) jadi replica ke VIP (yang mestinya nempel di DC1)
    demote_local_replica_to_vip

    # 2) Paksa DC1 jadi writer (jaga-jaga kalau masih replica)
    force_remote_writer

    log "Sukses BACKUP handler: DC2 REPLICA, DC1 WRITER"
    ;;

  fault)
    log "DC2 fault condition (no-op di sini)"
    ;;

  *)
    log "Event tidak dikenal: $TYPE"
    ;;
esac
