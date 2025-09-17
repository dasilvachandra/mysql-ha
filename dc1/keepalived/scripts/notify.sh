#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"

echo "[$(date '+%F %T')] DC1 VRRP event: $TYPE" >> "$LOG"

case "$TYPE" in
  master)
    # DC1 naik MASTER → arahkan route di hub ke db1
    ssh -o StrictHostKeyChecking=no root@10.7.0.1 -q -T "switch-db-route.sh db1" >> "$LOG" 2>&1
    ;;
  backup)
    echo "[$(date '+%F %T')] DC1 masuk BACKUP (no-op)" >> "$LOG"
    ;;
  fault)
    echo "[$(date '+%F %T')] DC1 fault condition" >> "$LOG"
    ;;
esac
