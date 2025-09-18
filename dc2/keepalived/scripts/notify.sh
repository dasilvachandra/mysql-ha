#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

MYSQL_CMD="docker exec -i mysql2 mysql -uroot -pabcdef"

ts(){ date '+%F %T'; }

echo "[$(ts)] DC2 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # Arahkan route di hub ke db2
    ssh -o StrictHostKeyChecking=no root@10.7.0.1 -q -T "switch-db-route.sh db2" >> "$LOG" 2>&1

    # Promote DC2
    $MYSQL_CMD < /etc/keepalived/scripts/promote_dc2.sql >> "$LOG" 2>&1

    # Remote DC1 dipaksa jadi replica ke VIP
    mysql -h10.7.0.4 -uha -pHaPassw0rd! < /etc/keepalived/scripts/demote_dc2.sql >> "$LOG" 2>&1

    echo "[$(ts)] Sukses MASTER handler: DC2 WRITER, DC1 REPLICA" >> "$LOG"
    ;;
  backup)
    # DC2 jadi replica ke VIP (anggap DC1 writer)
    $MYSQL_CMD < /etc/keepalived/scripts/demote_dc2.sql >> "$LOG" 2>&1

    # Pastikan DC1 dibuka write
    mysql -h10.7.0.4 -uha -pHaPassw0rd! < /etc/keepalived/scripts/promote_dc2.sql >> "$LOG" 2>&1

    echo "[$(ts)] Sukses BACKUP handler: DC2 REPLICA, DC1 WRITER" >> "$LOG"
    ;;
  fault)
    echo "[$(ts)] DC2 fault condition (no-op)" >> "$LOG"
    ;;
  *)
    echo "[$(ts)] Event tidak dikenal: $TYPE" >> "$LOG"
    ;;
esac
