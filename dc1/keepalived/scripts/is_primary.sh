#!/usr/bin/env bash
set -euo pipefail
MYSQL_HOST="127.0.0.1"
MYSQL_USER="root"
MYSQL_PASS="abcdef"

# Hanya cek mysql hidup
if mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASS" --silent; then
    exit 0
else
    exit 1
fi