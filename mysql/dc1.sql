-- ======================================================
-- DC1 bootstrap GTID auto-position replication (peer DC2: 10.7.0.5)
-- Aman di-run berulang (idempotent)
-- ======================================================

-- 0) Opsional: tambah user HA untuk kontrol via MySQL TCP dari peer wg (10.7.x.x)
CREATE USER IF NOT EXISTS 'ha'@'10.7.%' IDENTIFIED BY 'HaPassw0rd!';
GRANT SYSTEM_USER, SYSTEM_VARIABLES_ADMIN, SESSION_VARIABLES_ADMIN, RELOAD,
       REPLICATION SLAVE, REPLICATION CLIENT, PROCESS
ON *.* TO 'ha'@'10.7.%';
FLUSH PRIVILEGES;

-- 1) Siapkan user replikasi (kalau belum ada)
CREATE USER IF NOT EXISTS 'rep1'@'%' IDENTIFIED BY 'abcdef';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'rep1'@'%';
FLUSH PRIVILEGES;

-- 2) Anti tabrakan AUTO_INCREMENT (DC1 = offset 1)
--    (Persist agar bertahan setelah restart)
SET PERSIST auto_increment_increment = 2;
SET PERSIST auto_increment_offset    = 1;

-- 3) Bersihkan sisa channel replikasi bila ada
STOP REPLICA;
RESET REPLICA ALL;

-- 4) Subscribekan DC1 ke DC2 dengan GTID AUTO_POSITION
--    (mengikuti binlog DC2; public key diambil otomatis jika pakai caching_sha2_password)
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST           = '10.7.0.5',
  SOURCE_PORT           = 3306,
  SOURCE_USER           = 'rep1',
  SOURCE_PASSWORD       = 'abcdef',
  SOURCE_AUTO_POSITION  = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

-- 5) Mulai replikasi
START REPLICA;

-- 6) (Opsional) Set REPLICA agar read-only jika peran node ini bukan writer
--    Biarkan skrip failover (notify.sh) yang kontrol RO/RW saat produksi
-- SET GLOBAL super_read_only=1; 
-- SET GLOBAL read_only=1;

-- 7) Verifikasi ringkas
SHOW REPLICA STATUS\G
SELECT @@server_id AS server_id, @@gtid_mode AS gtid_mode, @@enforce_gtid_consistency AS enforce_gtid_consistency\G
