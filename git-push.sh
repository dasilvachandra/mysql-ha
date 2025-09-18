#!/usr/bin/env bash
set -euo pipefail

# Timestamp untuk pesan commit
ts="$(date '+%Y-%m-%d %H:%M:%S')"

# Hitung total baris dalam repo (abaikan .git)
total_lines=$(git ls-files | grep -v '^.git' | xargs cat 2>/dev/null | wc -l)

# Hitung perubahan dari staging area
stats=$(git diff --cached --shortstat || true)

# Ambil angka insertions dan deletions
insert=$(echo "$stats" | grep -o '[0-9]\+ insertion' | awk '{print $1}' || echo 0)
delete=$(echo "$stats" | grep -o '[0-9]\+ deletion' | awk '{print $1}' || echo 0)

# Total perubahan
change=$((insert + delete))

# Persentase perubahan (jaga jangan bagi nol)
if [ "$total_lines" -gt 0 ]; then
  percent=$((100 * change / total_lines))
else
  percent=0
fi

# Tambahkan file dulu
git add -A

# Commit dengan pesan ada timestamp & persen perubahan
git commit -m "Auto commit $ts | Perubahan: $change lines (~$percent%)"

# Push
git push
