-- ======================================================
-- INIT DB untuk Zabbix + User Replikasi
-- ======================================================

-- Hapus database lama kalau ada
DROP DATABASE IF EXISTS zabbix;
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

-- Buat user zabbix
DROP USER IF EXISTS 'zabbix'@'%';
CREATE USER 'zabbix'@'%' IDENTIFIED BY 'AndesZabbix!';

-- Beri hak penuh ke database zabbix
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';

-- Izinkan fungsi user didefinisikan (dibutuhkan Zabbix)
SET GLOBAL log_bin_trust_function_creators = 1;


-- ======================================================
-- User untuk replikasi (rep1)
-- ======================================================
DROP USER IF EXISTS 'rep1'@'%';
CREATE USER 'rep1'@'%' IDENTIFIED BY 'abcdef';

GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'rep1'@'%';

FLUSH PRIVILEGES;
