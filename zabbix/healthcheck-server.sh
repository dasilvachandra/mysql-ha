#!/usr/bin/env bash
set -euo pipefail
: "${DB_SERVER_HOST:?need DB_SERVER_HOST}"
: "${MYSQL_USER:?need MYSQL_USER}"
: "${MYSQL_PASSWORD:?need MYSQL_PASSWORD}"
: "${MYSQL_DATABASE:=zabbix}"
: "${DB_SERVER_PORT:=3306}"


# 1) DB reachability
if ! mysql -h"${DB_SERVER_HOST}" -P"${DB_SERVER_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e 'SELECT 1' "${MYSQL_DATABASE}" >/dev/null 2>&1; then
echo "DB not reachable"; exit 1
fi


# 2) zabbix_server process up & can answer version
if ! /usr/sbin/zabbix_server -V >/dev/null 2>&1; then
echo "zabbix_server not responding"; exit 1
fi


echo OK