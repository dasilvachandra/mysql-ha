📦 mysql-ha

Cluster MySQL High Availability lintas Data Center menggunakan WireGuard VPN, HAProxy, dan Keepalived.
Proyek ini menyediakan struktur direktori, konfigurasi, dan contoh deployment untuk membangun replikasi MySQL dengan failover otomatis menggunakan VIP yang berpindah antar-DC.

✨ Fitur

🔒 WireGuard VPN sebagai tunnel antar-DC.

🗄️ MySQL Group Replication (single-primary) untuk sinkronisasi data.

⚖️ HAProxy sebagai load balancer MySQL.

🛡️ Keepalived untuk virtual IP (VIP) failover antar node/DC.

📂 Struktur direktori modular (dc1/, dc2/, mysql/, docs/) agar mudah dikelola dan dikembangkan.

📂 Struktur Direktori
mysql-ha/
├── dc1/                  # Konfigurasi & compose untuk Data Center 1
├── dc2/                  # Konfigurasi & compose untuk Data Center 2
├── mysql/                # Konfigurasi MySQL (Group Replication)
├── docs/                 # Dokumentasi & catatan implementasi

🚀 Tujuan

Memberikan kerangka kerja (scaffold) untuk eksperimen dan implementasi MySQL HA lintas DC.

Memisahkan konfigurasi per DC agar mudah dimodifikasi sesuai kebutuhan.

Mendukung deployment berbasis Docker Compose maupun integrasi ke sistem produksi.