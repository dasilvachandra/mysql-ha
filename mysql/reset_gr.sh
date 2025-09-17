#!/usr/bin/env bash
set -euo pipefail

ROOT_PASS="AndesMysql123!"

log() { echo "[$(date '+%F %T')] $*"; }

# Pastikan parameter
if [[ $# -eq 0 ]]; then
  echo "❌ Harus ada parameter: dc1 atau dc2"
  echo "   Contoh: ./reset_gr.sh dc1"
  echo "           ./reset_gr.sh dc2"
  exit 1
fi

NODE="$1"
CONTAINER=""

case "$NODE" in
  dc1) CONTAINER="mysql1" ;;
  dc2) CONTAINER="mysql2" ;;
  *)
    echo "❌ Parameter tidak valid: $NODE"
    echo "Gunakan: dc1 atau dc2"
    exit 2
    ;;
esac

log "👉 Reset $NODE ($CONTAINER)..."

docker exec -i "$CONTAINER" mysql -uroot -p"$ROOT_PASS" <<EOF || true
STOP GROUP_REPLICATION;
UNINSTALL PLUGIN group_replication;
DROP USER IF EXISTS 'repl'@'%';
EOF

docker exec -i "$CONTAINER" rm -f /var/lib/mysql/auto.cnf || true

docker restart "$CONTAINER"

log "✅ $NODE ($CONTAINER) selesai direset"
log "ℹ️ Jalankan bootstrap_gr.sh $NODE untuk inisialisasi ulang"
