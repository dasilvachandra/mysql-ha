-- ======================================================
-- Init script untuk MySQL HA + Zabbix
-- Akan dijalankan hanya sekali saat container pertama kali dibuat
-- ======================================================

-- 1. Buat user untuk replikasi antar DC
DROP USER IF EXISTS 'rep1'@'%';
CREATE USER 'rep1'@'%' IDENTIFIED BY 'abcdef';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'rep1'@'%';

-- 2. Buat database untuk Zabbix
DROP DATABASE IF EXISTS zabbix;
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

-- 3. Buat user untuk Zabbix
DROP USER IF EXISTS 'zabbix'@'%';
CREATE USER 'zabbix'@'%' IDENTIFIED BY 'abcdef';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';

-- 4. Commit privilege
FLUSH PRIVILEGES;
