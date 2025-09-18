#!/usr/bin/env bash
set -euo pipefail

DC="${1:-}"

if [[ -z "$DC" ]]; then
  echo "Usage: $0 <dc1|dc2>"
  exit 1
fi

# Default user/pass (ubah kalau beda)
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-abcdef}"

# Nama container default
MYSQL_CONTAINER="mysql1"
SQL_FILE=""

if [[ "$DC" == "dc1" ]]; then
  SQL_FILE="mysql/dc1.sql"
  MYSQL_CONTAINER="mysql1"
elif [[ "$DC" == "dc2" ]]; then
  SQL_FILE="mysql/dc2.sql"
  MYSQL_CONTAINER="mysql2"
else
  echo "Argumen harus dc1 atau dc2"
  exit 1
fi

if [[ ! -f "$SQL_FILE" ]]; then
  echo "[ERROR] File SQL $SQL_FILE tidak ditemukan!"
  exit 1
fi

echo "[INFO] Menjalankan konfigurasi master-master untuk $DC"

# Kalau container ada, eksekusi via docker, kalau tidak langsung mysql host
if docker ps --format '{{.Names}}' | grep -qx "$MYSQL_CONTAINER"; then
  docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < "$SQL_FILE"
else
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < "$SQL_FILE"
fi

echo "[SUCCESS] SQL $SQL_FILE berhasil dijalankan di $DC"
