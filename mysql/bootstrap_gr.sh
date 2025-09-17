#!/usr/bin/env bash
set -euo pipefail

# =====================================
# Script bootstrap Group Replication
# DC1 = mysql1 (10.7.0.4)
# DC2 = mysql2 (10.7.0.5)
# =====================================

ROOT_PASS="AndesMysql123!"
REPL_USER="repl"
REPL_PASS="AndesRepl!"
SQL_FILE="$(dirname "$0")/bootstrap_gr.sql"

log() { echo "[$(date '+%F %T')] $*"; }

# Pastikan parameter
if [[ $# -eq 0 ]]; then
  echo "❌ Harus ada parameter: dc1 atau dc2"
  echo "   Contoh:"
  echo "     ./bootstrap_gr.sh dc1"
  echo "     ./bootstrap_gr.sh dc2"
  exit 1
fi

NODE="$1"

# Pastikan file SQL ada
if [[ ! -f "$SQL_FILE" ]]; then
  echo "❌ File $SQL_FILE tidak ditemukan"
  exit 1
fi

case "$NODE" in
  dc1)
    log "Apply SQL ke mysql1 (DC1)..."
    docker exec -i mysql1 mysql -uroot -p"$ROOT_PASS" < "$SQL_FILE"

    log "Bootstrap cluster di mysql1 (DC1)..."
    docker exec -i mysql1 mysql -uroot -p"$ROOT_PASS" <<EOF
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION USER='$REPL_USER', PASSWORD='$REPL_PASS';
SET GLOBAL group_replication_bootstrap_group=OFF;
EOF
    ;;

  dc2)
    log "Apply SQL ke mysql2 (DC2)..."
    docker exec -i mysql2 mysql -uroot -p"$ROOT_PASS" < "$SQL_FILE"

    log "Join cluster di mysql2 (DC2)..."
    docker exec -i mysql2 mysql -uroot -p"$ROOT_PASS" <<EOF
START GROUP_REPLICATION USER='$REPL_USER', PASSWORD='$REPL_PASS';
EOF
    ;;

  *)
    echo "❌ Parameter tidak valid: $NODE"
    echo "Gunakan: dc1 atau dc2"
    exit 1
    ;;
esac

# =====================================
# Cek status cluster (dari DC1 saja)
# =====================================
if [[ "$NODE" == "dc1" ]]; then
  log "Cek status cluster dari DC1..."
  docker exec -i mysql1 mysql -uroot -p"$ROOT_PASS" -e "
  SELECT MEMBER_HOST, MEMBER_ROLE, MEMBER_STATE
  FROM performance_schema.replication_group_members;
  "
fi

log "✅ Bootstrap selesai untuk $NODE"
