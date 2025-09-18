#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"
LOG="/var/log/keepalived-notify.log"
ZBX_CONTAINER="zbx-server-02"

ts(){ date '+%F %T'; }
log(){ echo "[$(ts)] DC2 VRRP event: $TYPE - $1" | tee -a "$LOG"; }

case "$TYPE" in
  master)
    log "DC2 naik MASTER → arahkan route hub ke db2 + start Zabbix"
    ssh -o StrictHostKeyChecking=no root@10.7.0.1 -q -T "switch-db-route.sh db2" >> "$LOG" 2>&1
    docker start $ZBX_CONTAINER >> "$LOG" 2>&1 || true
    ;;
  backup)
    log "DC2 masuk BACKUP → restart Zabbix agar cluster promote DC1"
    docker restart $ZBX_CONTAINER >> "$LOG" 2>&1 || true
    ;;
  fault)
    log "DC2 FAULT → restart Zabbix agar cluster promote DC1"
    docker restart $ZBX_CONTAINER >> "$LOG" 2>&1 || true
    ;;
  *)
    log "Unknown state: $TYPE"
    ;;
esac
