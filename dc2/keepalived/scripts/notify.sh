#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

# MySQL lokal (container di DC2)
MYSQL_CMD="docker exec -i mysql2 mysql -uroot -pabcdef"

# MySQL remote (langsung TCP ke DC1)
REMOTE_MYSQL="mysql -h10.7.0.4 -uha -pHaPassw0rd! --connect-timeout=3"

# File SQL lokal (DC2) & remote (DC1)
SQL_PROMOTE_LOCAL="/etc/keepalived/scripts/promote_dc2.sql"
SQL_DEMOTE_LOCAL="/etc/keepalived/scripts/demote_dc2.sql"
SQL_PROMOTE_REMOTE="/etc/keepalived/scripts/promote_dc1.sql"
SQL_DEMOTE_REMOTE="/etc/keepalived/scripts/demote_dc1.sql"

# Hub (opsional)
HUB="10.7.0.1"
SSH_OPTS="-o StrictHostKeyChecking=no -q -T"

ts(){ date '+%F %T'; }
log(){ echo "[$(ts)] $*" | tee -a "$LOG"; }

# Helper cek read_only remote (DC1)
remote_ro(){
  mysql -h10.7.0.4 -uha -pHaPassw0rd! -Nse "SELECT @@read_only" 2>/dev/null || echo "ERR"
}

echo "[$(ts)] DC2 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # 1) DEMOTE PEER (DC1) dulu → replica ke VIP (anti dual-writer)
    log "Demote DC1 ke REPLICA (VIP)"
    if ! $REMOTE_MYSQL < "$SQL_DEMOTE_REMOTE" >> "$LOG" 2>&1; then
      log "ERROR: demote DC1 gagal → ABORT promote (hindari dual-writer)"
      exit 1
    fi
    rro="$(remote_ro)"
    [[ "$rro" == "1" ]] || log "WARNING: verifikasi remote @@read_only=$rro"

    # 2) PROMOTE lokal (DC2) jadi writer
    log "Promote DC2 jadi WRITER"
    $MYSQL_CMD < "$SQL_PROMOTE_LOCAL" >> "$LOG" 2>&1

    # 3) Switch route di HUB ke db2 (setelah writer siap)
    ssh $SSH_OPTS "root@$HUB" "switch-db-route.sh db2" >> "$LOG" 2>&1 || true

    log "Sukses MASTER handler: DC2 WRITER, DC1 REPLICA"
    ;;

  backup)
    # 1) DEMOTE lokal (DC2) → replica ke VIP
    log "Demote DC2 ke REPLICA (VIP)"
    $MYSQL_CMD < "$SQL_DEMOTE_LOCAL" >> "$LOG" 2>&1 || { log "ERROR: demote DC2 gagal"; exit 1; }

    # 2) PROMOTE remote (DC1) jadi writer (best-effort)
    log "Promote DC1 jadi WRITER"
    $REMOTE_MYSQL < "$SQL_PROMOTE_REMOTE" >> "$LOG" 2>&1 || log "WARNING: promote DC1 gagal (cek manual)"

    # 3) Switch route di HUB ke db1
    ssh $SSH_OPTS "root@$HUB" "switch-db-route.sh db1" >> "$LOG" 2>&1 || true

    log "Sukses BACKUP handler: DC2 REPLICA, DC1 WRITER"
    ;;

  fault)
    log "DC2 fault condition (no-op)"
    ;;

  *)
    log "Event tidak dikenal: $TYPE"
    ;;
esac
