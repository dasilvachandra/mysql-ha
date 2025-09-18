#!/usr/bin/env bash
set -euo pipefail
# Try to fetch front page; return fail if not 200
status=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/)
[ "$status" = "200" ] || { echo "HTTP $status"; exit 1; }
echo OK