-- Promote DC1 (writer)
STOP REPLICA;
RESET REPLICA ALL;
SET GLOBAL super_read_only=0;
SET GLOBAL read_only=0;
