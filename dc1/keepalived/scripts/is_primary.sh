#!/usr/bin/env bash
set -euo pipefail
docker exec -i mysql1 mysql -uroot -pabcdef -Nse "SELECT @@read_only" 2>/dev/null | grep -qx "0"
