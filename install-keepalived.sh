#!/usr/bin/env bash
set -euo pipefail

# === PARAMETER ===
DC="${1:-}"
if [[ -z "$DC" ]]; then
  echo "Usage: $0 <dc1|dc2>"
  exit 1
fi

if [[ "$DC" != "dc1" && "$DC" != "dc2" ]]; then
  echo "Error: Parameter harus dc1 atau dc2"
  exit 1
fi

SRC_DIR="$(dirname "$0")/../$DC/keepalived"

echo "[INFO] Install keepalived + mysql-client"
apt update -y
apt install -y keepalived mysql-client

echo "[INFO] Buat direktori konfigurasi"
mkdir -p /etc/keepalived/scripts
mkdir -p /etc/systemd/system/keepalived.service.d

echo "[INFO] Copy konfigurasi keepalived ($DC)"
cp "$SRC_DIR/keepalived.conf" /etc/keepalived/keepalived.conf

echo "[INFO] Copy semua script SQL & bash"
cp "$SRC_DIR/scripts/"*.sh /etc/keepalived/scripts/ || true
cp "$SRC_DIR/scripts/"*.sql /etc/keepalived/scripts/ || true
chmod +x /etc/keepalived/scripts/*.sh || true

if [[ -f "$SRC_DIR/keepalived.service.d/override.conf" ]]; then
  echo "[INFO] Pasang systemd override (wait WireGuard)"
  cp "$SRC_DIR/keepalived.service.d/override.conf" \
     /etc/systemd/system/keepalived.service.d/override.conf
fi

echo "[INFO] Reload systemd & enable keepalived"
systemctl daemon-reload
systemctl enable keepalived
systemctl restart keepalived

echo "[INFO] Status keepalived:"
systemctl --no-pager --full status keepalived || true

echo "[SUCCESS] Instalasi keepalived untuk $DC selesai."
