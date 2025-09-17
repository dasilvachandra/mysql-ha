#!/bin/bash
# Script otomatis git force pull dengan timestamp log

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "🔄 [$TIMESTAMP] Menarik update terbaru (force pull) dari remote..."

# Ambil semua update remote
git fetch --all

# Reset ke remote main (hapus perubahan lokal)
git reset --hard origin/main

echo "✅ [$TIMESTAMP] Force pull selesai (sinkron dengan origin/main)"
