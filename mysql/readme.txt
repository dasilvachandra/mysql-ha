Langkah 1. Apply ke kedua node (DC1 & DC2)

DC1

docker exec -it mysql1 mysql -uroot -pAndesMysql123! < ~/mysql-ha/mysql/bootstrap_gr.sql


DC2

docker exec -it mysql2 mysql -uroot -pAndesMysql123! < ~/mysql-ha/mysql/bootstrap_gr.sql


Ini akan install plugin, buat user repl, dan enable trust function di kedua node.

Langkah 2. Bootstrap cluster di DC1
docker exec -it mysql1 mysql -uroot -pAndesMysql123! -e "
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION USER='repl', PASSWORD='AndesRepl!';
SET GLOBAL group_replication_bootstrap_group=OFF;
SELECT * FROM performance_schema.replication_group_members;
"


Harus muncul 1 member (10.7.0.4) dengan PRIMARY.

Langkah 3. Join DC2 ke cluster
docker exec -it mysql2 mysql -uroot -pAndesMysql123! -e "
START GROUP_REPLICATION USER='repl', PASSWORD='AndesRepl!';
SELECT * FROM performance_schema.replication_group_members;
"


Harus muncul 2 member (10.7.0.4 & 10.7.0.5) dengan status ONLINE.

Langkah 4. Tes replikasi

Buat DB di DC1:

docker exec -it mysql1 mysql -uroot -pAndesMysql123! -e "CREATE DATABASE test_dc1;"


Cek di DC2:

docker exec -it mysql2 mysql -uroot -pAndesMysql123! -e "SHOW DATABASES LIKE 'test_dc1';"


Kalau muncul → berarti GR sinkron.


👉 Jadi alurnya:
1. Simpan bootstrap_gr.sql di ~/mysql-ha/mysql/.
2. Jalankan di kedua node (DC1 & DC2).
3. Bootstrap cluster dari DC1.
4. Join cluster dari DC2.