-- ======================================================
-- User untuk replikasi (rep1)
-- ======================================================
DROP USER IF EXISTS 'rep1'@'%';
CREATE USER 'rep1'@'%' IDENTIFIED BY 'abcdef';

GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'rep1'@'%';

FLUSH PRIVILEGES;

-- User & database untuk Zabbix
DROP DATABASE IF EXISTS zabbix;
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

DROP USER IF EXISTS 'zabbix'@'%';
CREATE USER 'zabbix'@'%' IDENTIFIED BY 'abcdef';

GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';
FLUSH PRIVILEGES;