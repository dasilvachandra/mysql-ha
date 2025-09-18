#!/usr/bin/env bash
set -euo pipefail

ts="$(date '+%Y-%m-%d %H:%M:%S')"
branch="$(git rev-parse --abbrev-ref HEAD)"

# Ada perubahan?
if [[ -z "$(git status --porcelain=v1)" ]]; then
  echo "✅ Tidak ada perubahan file."
  exit 0
fi

echo "🗂  Staging semua perubahan (termasuk delete/rename)…"
git add -A

# Pastikan memang ada yang staged
if [[ -z "$(git diff --cached --name-only)" ]]; then
  echo "ℹ️  Tidak ada perubahan yang ter-stage."
  exit 0
fi

# Hitung total baris repo (opsional, untuk persentase)
# Aman jika repo besar? Kalau takut lambat, boleh skip bagian ini.
total_lines=$(git ls-files -z | xargs -0 cat 2>/dev/null | wc -l | awk '{print $1}')
[[ -z "$total_lines" ]] && total_lines=0

# Hitung total insert/delete yang AKAN di-commit
read -r ins del <<<"$(git diff --cached --numstat | awk '{a+=$1; b+=$2} END{print (a+0) " " (b+0)}')"
change=$((ins + del))
if (( total_lines > 0 )); then
  percent=$(( 100 * change / total_lines ))
else
  percent=0
fi

msg="update: $ts | +$ins -$del (~$percent%)"
echo "📝 Commit: $msg"
git commit -m "$msg"

echo "🚀 Push ke remote (origin $branch)…"
git push origin "$branch"
echo "✅ Selesai."
