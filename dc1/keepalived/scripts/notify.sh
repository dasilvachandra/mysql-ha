#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

MYSQL_CMD="docker exec -i mysql1 mysql -uroot -pabcdef"

ts(){ date '+%F %T'; }

echo "[$(ts)] DC1 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # Arahkan route di hub ke db1
    ssh -o StrictHostKeyChecking=no root@10.7.0.1 -q -T "switch-db-route.sh db1" >> "$LOG" 2>&1

    # Promote DC1
    $MYSQL_CMD < /etc/keepalived/scripts/promote_dc1.sql >> "$LOG" 2>&1

    # Remote DC2 dipaksa jadi replica ke VIP
    mysql -h10.7.0.5 -uha -pHaPassw0rd! < /etc/keepalived/scripts/demote_dc1.sql >> "$LOG" 2>&1

    echo "[$(ts)] Sukses MASTER handler: DC1 WRITER, DC2 REPLICA" >> "$LOG"
    ;;
  backup)
    # DC1 jadi replica ke VIP (anggap DC2 writer)
    $MYSQL_CMD < /etc/keepalived/scripts/demote_dc1.sql >> "$LOG" 2>&1

    # Pastikan DC2 dibuka write
    mysql -h10.7.0.5 -uha -pHaPassw0rd! < /etc/keepalived/scripts/promote_dc1.sql >> "$LOG" 2>&1

    echo "[$(ts)] Sukses BACKUP handler: DC1 REPLICA, DC2 WRITER" >> "$LOG"
    ;;
  fault)
    echo "[$(ts)] DC1 fault condition (no-op)" >> "$LOG"
    ;;
  *)
    echo "[$(ts)] Event tidak dikenal: $TYPE" >> "$LOG"
    ;;
esac
