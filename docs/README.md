# mysql-ha

Cluster **MySQL High Availability + Zabbix HA** lintas Data Center menggunakan **WireGuard VPN** dan **Keepalived VIP**.

## Struktur Direktori
- `dc1/`, `dc2/` → konfigurasi per Data Center (docker-compose untuk MySQL & Zabbix).  
- `mysql/` → konfigurasi MySQL Group Replication.  
- `zabbix/` → konfigurasi Zabbix server & frontend.  
- `docs/` → catatan & dokumentasi bootstrap.  

## Mekanisme HA
- **Database** direplikasi menggunakan **MySQL Group Replication** (single-primary mode) antara DC1 & DC2.  
- **Keepalived** mengelola Virtual IP (**10.7.0.10**) untuk semua layanan:  
  - `10.7.0.10:3306` → MySQL cluster  
  - `10.7.0.10:10051` → Zabbix server  
  - `10.7.0.10:8080` → Zabbix frontend (Web UI)  
- **Failover**: Jika DC1 down, DC2 akan otomatis mengambil alih VIP, begitu juga sebaliknya.  
- **Zabbix Server** berjalan di DC1 & DC2 dengan HA mode (`HANodeName` berbeda, hanya 1 node aktif).  
- **Zabbix Frontend** tersedia di kedua DC, diakses melalui **VIP yang sama**.  

## Catatan
- **WireGuard** harus sudah dikonfigurasi di host (bukan container).  
- Semua container MySQL & Zabbix tetap berjalan di kedua DC.  
- VIP `10.7.0.10` berpindah otomatis antar DC melalui **Keepalived**.  
- Monitoring client (misalnya NMS atau pengguna web) cukup mengakses VIP saja, tanpa perlu tahu node mana yang sedang aktif.  
