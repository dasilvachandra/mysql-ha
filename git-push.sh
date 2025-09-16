#!/bin/bash
# Script otomatis git add, commit, push dengan pesan timestamp

# Ambil timestamp sekarang
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Jalankan perintah git
echo "🔄 Menambahkan file ke staging..."
git add .

echo "📝 Commit dengan pesan: update: $TIMESTAMP"
git commit -m "update: $TIMESTAMP"

echo "🚀 Push ke remote (origin main)..."
git push origin main