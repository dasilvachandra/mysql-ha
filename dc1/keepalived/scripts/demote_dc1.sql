-- Demote DC1 jadi replica ke VIP
SET GLOBAL super_read_only=1;
SET GLOBAL read_only=1;
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
  SOURCE_HOST           = '10.7.0.10',
  SOURCE_PORT           = 3306,
  SOURCE_USER           = 'rep1',
  SOURCE_PASSWORD       = 'abcdef',
  SOURCE_AUTO_POSITION  = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;
