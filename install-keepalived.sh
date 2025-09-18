#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Install keepalived + mysql-client"
apt update -y
apt install -y keepalived mysql-client

echo "[INFO] Buat direktori konfigurasi"
mkdir -p /etc/keepalived/scripts
mkdir -p /etc/systemd/system/keepalived.service.d

echo "[INFO] Copy konfigurasi keepalived"
cp ./keepalived/keepalived.conf /etc/keepalived/keepalived.conf

echo "[INFO] Copy semua script SQL & bash"
cp ./keepalived/scripts/*.sh /etc/keepalived/scripts/
cp ./keepalived/scripts/*.sql /etc/keepalived/scripts/
chmod +x /etc/keepalived/scripts/*.sh

echo "[INFO] Pasang systemd override (wait WireGuard)"
cp ./keepalived/keepalived.service.d/override.conf /etc/systemd/system/keepalived.service.d/override.conf

echo "[INFO] Reload systemd & enable keepalived"
systemctl daemon-reload
systemctl enable keepalived
systemctl restart keepalived

echo "[INFO] Status keepalived:"
systemctl --no-pager --full status keepalived
