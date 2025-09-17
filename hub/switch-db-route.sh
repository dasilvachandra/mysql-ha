#!/usr/bin/env bash
set -euo pipefail

# === KONFIGURASI ===
PEER_DB1='CjSFysbRyWptPxd4HdcRpsjbA8wvtnsMAKUXu92v/Wo='
PEER_DB2='Z9J4PiuLH6cwTtmTgGqP9EuP7Wq4IOdHYtdOef75oVE='
WG_IF='wg0'
SUBNET='10.7.0.10/32'
WG_NET='10.7.0.0/24'
LOG='/var/log/switch-db-route.log'

log(){ echo "[$(date +'%F %T')] $*" | tee -a "$LOG"; }

require(){
  command -v "$1" >/dev/null 2>&1 || { echo "Missing $1"; exit 1; }
}

require wg
require ip

TARGET="${1:-}"
if [[ "$TARGET" != "db1" && "$TARGET" != "db2" ]]; then
  echo "Usage: $0 {db1|db2}"
  exit 2
fi

log "Switching $SUBNET via $TARGET"

# Pastikan rute besar diarahkan ke wg0, biar failover nggak perlu ubah route
ip route replace "$SUBNET" dev "$WG_IF" || true

if [[ "$TARGET" == "db1" ]]; then
  wg set "$WG_IF" peer "$PEER_DB1" allowed-ips 10.7.0.4/32,"$SUBNET"
  wg set "$WG_IF" peer "$PEER_DB2" allowed-ips 10.7.0.5/32
else
  wg set "$WG_IF" peer "$PEER_DB1" allowed-ips 10.7.0.4/32
  wg set "$WG_IF" peer "$PEER_DB2" allowed-ips 10.7.0.5/32,"$SUBNET"
fi

# Verifikasi
sleep 1
WG_SHOW="$(wg show)"
echo "$WG_SHOW" | grep -q "$SUBNET" || { log "ERROR: $SUBNET belum terpasang di AllowedIPs mana pun"; exit 3; }

# Pastikan kernel routing benar
ip route get "$(echo "$SUBNET" | cut -d/ -f1)" >/dev/null 2>&1 || {
  log "WARNING: ip route get gagal — cek tabel route"
}

log "OK: $SUBNET via $TARGET"
exit 0