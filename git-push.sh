#!/usr/bin/env bash
set -euo pipefail

ts="$(date '+%Y-%m-%d %H:%M:%S')"

# Ambil daftar file yang berubah (sudah di-tracked atau baru)
files=$(git status --porcelain | awk '{print $2}')

if [ -z "$files" ]; then
  echo "✅ Tidak ada perubahan file."
  exit 0
fi

# Hitung total baris repo untuk persentase
total_lines=$(git ls-files | xargs cat 2>/dev/null | wc -l)

for f in $files; do
  # Stage file ini
  git add "$f"

  # Hitung perubahan baris file ini
  stats=$(git diff --cached --numstat "$f" || true)
  insert=$(echo "$stats" | awk '{print $1}')
  delete=$(echo "$stats" | awk '{print $2}')
  change=$((insert + delete))

  if [ "$total_lines" -gt 0 ]; then
    percent=$((100 * change / total_lines))
  else
    percent=0
  fi

  echo "📝 Commit $f dengan pesan: update($f) $ts | $change lines (~$percent%)"
  git commit -m "update($f): $ts | Perubahan: $change lines (~$percent%)"
done

echo "🚀 Push semua commit ke remote (origin main)..."
git push origin main
