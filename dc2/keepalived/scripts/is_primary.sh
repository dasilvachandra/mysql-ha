#!/usr/bin/env bash
set -euo pipefail

MYSQL_HOST="127.0.0.1"
MYSQL_USER="root"
MYSQL_PASS="abcdef"

# 1) mysqld hidup?
if ! mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASS" --silent; then
  exit 1
fi

# 2) node ini PRIMARY?
ROLE="$(mysql -N -B -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASS" \
  -e "SELECT MEMBER_ROLE FROM performance_schema.replication_group_members
      WHERE MEMBER_HOST = @@report_host LIMIT 1;" 2>/dev/null || echo "")"

[[ "$ROLE" == "PRIMARY" ]] && exit 0 || exit 2
