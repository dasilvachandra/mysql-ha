#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"
ZBX_CONTAINER="zbx-server-01"

ts(){ date '+%F %T'; }
log(){ echo "[$(ts)] DC1 VRRP event: $TYPE - $1" | tee -a "$LOG"; }

case "$TYPE" in
  master)
    log "DC1 naik MASTER → arahkan route hub ke db1 + start Zabbix"
    ssh -o StrictHostKeyChecking=no root@10.7.0.1 -q -T "switch-db-route.sh db1" >> "$LOG" 2>&1
    docker start $ZBX_CONTAINER >> "$LOG" 2>&1 || true
    ;;
  backup)
    log "DC1 masuk BACKUP → restart Zabbix agar cluster promote DC2"
    docker restart $ZBX_CONTAINER >> "$LOG" 2>&1 || true
    ;;
  fault)
    log "DC1 FAULT → restart Zabbix agar cluster promote DC2"
    docker restart $ZBX_CONTAINER >> "$LOG" 2>&1 || true
    ;;
  *)
    log "Unknown state: $TYPE"
    ;;
esac
