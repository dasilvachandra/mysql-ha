-- ======================================================
-- User untuk replikasi (rep1)
-- ======================================================
DROP USER IF EXISTS 'rep1'@'%';
CREATE USER 'rep1'@'%' IDENTIFIED BY 'abcdef';

GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'rep1'@'%';

FLUSH PRIVILEGES;
