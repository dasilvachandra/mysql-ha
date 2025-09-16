# mysql-ha

Cluster **MySQL High Availability + Zabbix HA** lintas Data Center menggunakan **WireGuard VPN** dan **HAProxy VIP**.

## Struktur Direktori
- `dc1/`, `dc2/` → konfigurasi per Data Center (docker-compose untuk MySQL & Zabbix).  
- `hub/` → HAProxy di hub, menyediakan Virtual IP (VIP) untuk failover.  
- `mysql/` → konfigurasi MySQL Group Replication.  
- `zabbix/` → konfigurasi Zabbix server & frontend.  
- `docs/` → catatan & dokumentasi bootstrap.

## Mekanisme HA
- **Database** direplikasi menggunakan **MySQL Group Replication** (single-primary mode) antara DC1 & DC2.  
- **HAProxy di hub** menyediakan Virtual IP (**10.7.0.100**) untuk semua layanan:  
  - `10.7.0.100:3306` → MySQL cluster  
  - `10.7.0.100:10051` → Zabbix server  
  - `10.7.0.100:8080` → Zabbix frontend (Web UI)  
- **Zabbix Server** berjalan di DC1 & DC2 dengan HA mode (HANodeName berbeda, hanya 1 node aktif).  
- **Zabbix Frontend** tersedia di kedua DC, diakses melalui VIP hub.

## Catatan
- WireGuard harus sudah dikonfigurasi di host (bukan container).  
- Semua container berada dalam network `zabbix_net` (10.11.12.0/24).  
- IP host digunakan untuk komunikasi **Group Replication** antar-DC (10.7.0.4, 10.7.0.5).  
- Tidak ada Keepalived, failover murni di-handle oleh **HAProxy di hub**.