📦 mysql-ha

Cluster **MySQL + Zabbix High Availability** lintas Data Center menggunakan **WireGuard VPN** dan **HAProxy VIP**.  
Proyek ini menyediakan struktur direktori, konfigurasi, dan contoh deployment untuk membangun replikasi MySQL dengan failover otomatis dan integrasi Zabbix HA.

✨ Fitur

🔒 WireGuard VPN sebagai tunnel antar-DC.  
🗄️ MySQL Group Replication (single-primary) untuk sinkronisasi data.  
⚖️ HAProxy di hub sebagai load balancer sekaligus Virtual IP (VIP).  
📊 Zabbix server & frontend berjalan di DC1 dan DC2 dengan HA mode.  
📂 Struktur direktori modular (dc1/, dc2/, mysql/, zabbix/, hub/, docs/).

📂 Struktur Direktori

mysql-ha/
├── dc1/          # Konfigurasi & compose untuk Data Center 1 (MySQL, Zabbix)
├── dc2/          # Konfigurasi & compose untuk Data Center 2 (MySQL, Zabbix)
├── hub/          # HAProxy VIP untuk MySQL & Zabbix
├── mysql/        # Konfigurasi MySQL Group Replication
├── zabbix/       # Dockerfile & compose Zabbix server + frontend
├── docs/         # Dokumentasi & catatan implementasi

🚀 Tujuan

- Memberikan kerangka kerja (scaffold) untuk eksperimen dan implementasi MySQL + Zabbix HA lintas DC.  
- Memisahkan konfigurasi per DC agar mudah dimodifikasi sesuai kebutuhan.  
- Mendukung deployment berbasis Docker Compose maupun integrasi ke sistem produksi.