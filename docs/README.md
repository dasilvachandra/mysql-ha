# mysql-ha

Cluster **MySQL High Availability** lintas Data Center menggunakan **WireGuard VPN**, **HAProxy**, dan **Keepalived**.

## Struktur Direktori
- `dc1/`, `dc2/` → konfigurasi per Data Center (docker-compose, HAProxy, Keepalived, script).
- `mysql/` → konfigurasi MySQL Group Replication untuk DC1 & DC2.
- `docs/` → catatan & dokumentasi bootstrap.

## Catatan
- WireGuard sudah di-setup langsung di host (bukan container).
- Route antar-subnet container (172.20.1.0/24 ↔ 172.20.2.0/24) dilewatkan via `wg0` host.
- Keepalived mengatur VIP `10.7.0.10` di interface `wg0`.
- MySQL dijalankan dengan **Group Replication single-primary**.
