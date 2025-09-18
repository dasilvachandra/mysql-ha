-- Jalankan di DC2 (10.7.0.5)
STOP REPLICA;
RESET REPLICA ALL;

-- Set AUTO_INCREMENT supaya tidak tabrakan ID
SET PERSIST auto_increment_increment = 2;
SET PERSIST auto_increment_offset    = 2;

-- Buat user replikasi (aman jika sudah ada)
CREATE USER IF NOT EXISTS 'rep1'@'%' IDENTIFIED BY 'abcdef';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'rep1'@'%';
FLUSH PRIVILEGES;

-- Replikasi dari DC1 -> DC2
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST           = '10.7.0.4',
  SOURCE_PORT           = 3306,
  SOURCE_USER           = 'rep1',
  SOURCE_PASSWORD       = 'abcdef',
  SOURCE_AUTO_POSITION  = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;

SHOW REPLICA STATUS\G
