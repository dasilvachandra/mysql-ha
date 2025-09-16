DROP DATABASE IF EXISTS zabbix;
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

DROP USER IF EXISTS 'zabbix'@'10.11.12.1';
CREATE USER 'zabbix'@'10.11.12.1' IDENTIFIED BY 'AndesZabbix!';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'10.11.12.1';

SET GLOBAL log_bin_trust_function_creators = 1;