-- ======================================================
-- Init script untuk konfigurasi DC2 sebagai replica DC1
-- ======================================================

-- Pastikan tidak ada replikasi lama
STOP REPLICA;
RESET REPLICA ALL;

-- Atur source replication (DC1 → DC2)
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '10.7.0.4',
  SOURCE_PORT = 3306,
  SOURCE_USER = 'rep1',
  SOURCE_PASSWORD = 'abcdef',
  SOURCE_LOG_FILE = 'binlog.000005',   -- hasil SHOW MASTER STATUS di DC1
  SOURCE_LOG_POS  = 1433,              -- hasil SHOW MASTER STATUS di DC1
  SOURCE_SSL = 1;

-- Mulai proses replikasi
START REPLICA;

-- Verifikasi status
SHOW REPLICA STATUS\G
