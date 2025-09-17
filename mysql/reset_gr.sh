#!/usr/bin/env bash
set -euo pipefail

ROOT_PASS="AndesMysql123!"
NODES=("mysql1" "mysql2")

log() { echo "[$(date '+%F %T')] $*"; }

for NODE in "${NODES[@]}"; do
  log "👉 Reset $NODE..."

  # Stop GR + uninstall plugin + drop repl user
  docker exec -i $NODE mysql -uroot -p"$ROOT_PASS" <<EOF || true
STOP GROUP_REPLICATION;
UNINSTALL PLUGIN group_replication;
DROP USER IF EXISTS 'repl'@'%';
EOF

  # Hapus file auto.cnf biar UUID cluster regenerate baru
  docker exec -i $NODE rm -f /var/lib/mysql/auto.cnf || true

  # Restart container
  docker restart $NODE
done

log "✅ Semua node direset."
log "ℹ️ Jalankan ulang bootstrap: ./bootstrap_gr.sh dc1 lalu ./bootstrap_gr.sh dc2"
