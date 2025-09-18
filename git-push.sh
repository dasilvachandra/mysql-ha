#!/usr/bin/env bash
set -euo pipefail

ts="$(date '+%Y-%m-%d %H:%M:%S')"

# Tambahkan file dulu ke staging
git add -A

# Hitung total baris di repo
total_lines=$(git ls-files | grep -v '^.git' | xargs cat 2>/dev/null | wc -l)

# Hitung perubahan yang ada di staging
stats=$(git diff --cached --shortstat || true)

# Ambil angka insertions dan deletions
insert=$(echo "$stats" | grep -o '[0-9]\+ insertion' | awk '{print $1}' || echo 0)
delete=$(echo "$stats" | grep -o '[0-9]\+ deletion' | awk '{print $1}' || echo 0)

change=$((insert + delete))

if [ "$total_lines" -gt 0 ]; then
  percent=$((100 * change / total_lines))
else
  percent=0
fi

# Commit dengan detail
git commit -m "Auto commit $ts | Perubahan: $change lines (~$percent%)"

# Push sekali
git push origin main
