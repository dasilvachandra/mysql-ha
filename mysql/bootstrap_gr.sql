-- =====================================================
-- Bootstrap MySQL Group Replication untuk DC1 & DC2
-- DC1 = 10.7.0.4, DC2 = 10.7.0.5
-- =====================================================

-- 1. Install plugin Group Replication
INSTALL PLUGIN group_replication SONAME 'group_replication.so';

-- 2. Buat user repl
DROP USER IF EXISTS 'repl'@'%';
CREATE USER 'repl'@'%' IDENTIFIED BY 'AndesRepl!';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

-- 3. Pastikan fungsi boleh direplikasi
SET GLOBAL log_bin_trust_function_creators = 1;

-- Catatan:
-- Jalankan SET GLOBAL group_replication_bootstrap_group=ON hanya di DC1
-- Setelah start, segera OFF-kan lagi.
