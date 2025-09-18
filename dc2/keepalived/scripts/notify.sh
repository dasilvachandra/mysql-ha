#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

echo "[$(date '+%F %T')] DC2 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # DC2 naik MASTER → arahkan route di hub ke db2
    ssh -o StrictHostKeyChecking=no root@10.7.0.1 -q -T "switch-db-route.sh db2" >> "$LOG" 2>&1
    ;;
  backup)
    echo "[$(date '+%F %T')] DC2 masuk BACKUP (no-op)" >> "$LOG"
    ;;
  fault)
    echo "[$(date '+%F %T')] DC2 fault condition" >> "$LOG"
    ;;
esac
