#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(dirname "$0")"

if [[ $# -eq 0 ]]; then
  echo "❌ Harus ada parameter! Contoh:"
  echo "   ./rebuild.sh dc1"
  echo "   ./rebuild.sh dc2"
  echo "   ./rebuild.sh hub"
  exit 1
fi

TARGET="$1"
TARGET_DIR="$BASE_DIR/$TARGET"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Folder $TARGET_DIR tidak ditemukan!"
  exit 2
fi

echo "🚀 Rebuild docker compose untuk: $TARGET"
echo "========================================="
docker network create zbxnet
cd "$TARGET_DIR"

echo "🔨 docker compose build..."
docker compose build --no-cache

echo "⬆️ docker compose up -d..."
docker compose up -d

echo "✅ $TARGET selesai"

echo ""
echo "🎉 Service $TARGET berhasil direbuild & dijalankan!"
