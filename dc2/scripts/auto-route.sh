#!/usr/bin/env bash
set -euo pipefail

DC=DC2

# tunggu interface wg0
for i in {1..20}; do
  ip link show wg0 &>/dev/null && break
  sleep 1
done

if ! ip link show wg0 &>/dev/null; then
  echo "wg0 tidak ditemukan, pastikan WireGuard aktif." >&2
  exit 1
fi

# Tambah route ke subnet DC1
ip route replace 172.20.1.0/24 via 10.7.0.4 dev wg0
