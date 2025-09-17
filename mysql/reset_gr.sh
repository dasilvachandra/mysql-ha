#!/usr/bin/env bash
set -euo pipefail

ROOT_PASS="AndesMysql123!"
NODE=${1:-}

if [[ -z "$NODE" ]]; then
  echo "❌ Harus ada parameter: mysql1 atau mysql2"
  echo "   Contoh: ./reset_gr.sh mysql1"
  exit 1
fi

log() { echo "[$(date '+%F %T')] $*"; }

log "👉 Reset $NODE..."

docker exec -i $NODE mysql -uroot -p"$ROOT_PASS" <<EOF || true
STOP GROUP_REPLICATION;
UNINSTALL PLUGIN group_replication;
DROP USER IF EXISTS 'repl'@'%';
EOF

docker exec -i $NODE rm -f /var/lib/mysql/auto.cnf || true

docker restart $NODE

log "✅ $NODE selesai direset"
