#!/bin/bash
# Script otomatis git add, commit per file, lalu push sekali

# Ambil daftar file yang berubah (modified, new, deleted di working tree)
FILES=$(git status --porcelain | awk '{print $2}')

if [ -z "$FILES" ]; then
  echo "✅ Tidak ada perubahan file."
  exit 0
fi

for FILE in $FILES; do
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "🔄 Menambahkan $FILE..."
  git add "$FILE"
  
  echo "📝 Commit $FILE dengan pesan: update($FILE): $TIMESTAMP"
  git commit -m "update($FILE): $TIMESTAMP"
done

echo "🚀 Push semua commit ke remote (origin main)..."
git push origin main
