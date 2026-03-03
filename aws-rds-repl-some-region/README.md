# Aurora MySQL のクロスリージョンレプリケーションを同一リージョンで使ってみる

プライマリを構築

```sh
terraform apply -var skip_secondary=true
```

プライマリで DB とテーブルを作成

```sql
create database test;
create database test2;

use test;
create table t (id int not null primary key);
insert into t values (1);
insert into t values (2);
insert into t values (3);
select * from t;

use test2;
create table t (id int not null primary key);
insert into t values (4);
insert into t values (5);
insert into t values (6);
select * from t;
```

セカンダリを構築

```sh
terraform apply
```

プライマリでデータ更新

```sql
use test;
insert into t values (4);
delete from t where id = 3;
select * from t;
+----+
| id |
+----+
|  1 |
|  2 |
|  4 |
+----+

use test2;
insert into t values (7);
delete from t where id = 5;
select * from t;
+----+
| id |
+----+
|  4 |
|  6 |
|  7 |
+----+

show master status;
+----------------------------+----------+--------------+------------------+-------------------+
| File                       | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+----------------------------+----------+--------------+------------------+-------------------+
| mysql-bin-changelog.000004 |     2046 | test         |                  |                   |
+----------------------------+----------+--------------+------------------+-------------------+

show slave hosts;
+-----------+------+------+------------+--------------------------------------+
| Server_id | Host | Port | Master_id  | Slave_UUID                           |
+-----------+------+------+------------+--------------------------------------+
| 756598322 |      | 3306 | 1326515398 | 1c55eb9e-7c9c-337e-8ef4-f123583e992a |
+-----------+------+------+------------+--------------------------------------+
```

セカンダリでデータ確認

```sql
use test;
select * from t;
+----+
| id |
+----+
|  1 |
|  2 |
|  4 |
+----+

use test2;
select * from t;
+----+
| id |
+----+
|  4 |
|  5 |
|  6 |
+----+

show slave status \G
--                Slave_IO_State: Waiting for source to send event
--                   Master_Host: 10.7.15.0
--                   Master_User: rdsrepladmin
--                   Master_Port: 3306
--                 Connect_Retry: 60
--               Master_Log_File: mysql-bin-changelog.000004
--           Read_Master_Log_Pos: 2046
--                Relay_Log_File: relaylog.000002
--                 Relay_Log_Pos: 892
--         Relay_Master_Log_File: mysql-bin-changelog.000004
--              Slave_IO_Running: Yes
--             Slave_SQL_Running: Yes
--               Replicate_Do_DB: test
--           Replicate_Ignore_DB:
--            Replicate_Do_Table:
--        Replicate_Ignore_Table:
--       Replicate_Wild_Do_Table:
--   Replicate_Wild_Ignore_Table: mysql.%
--                    Last_Errno: 0
--                    Last_Error:
--                          ...snip...
```

競合を起こす

```sql
-- セカンダリ
use test;
insert into t values (10);
+----+
| id |
+----+
|  1 |
|  2 |
|  4 |
+----+

-- プライマリ
use test;
insert into t values (10);

-- セカンダリ
show slave status \G
--                Slave_IO_State: Waiting for source to send event
--                   Master_Host: 10.7.15.0
--                   Master_User: rdsrepladmin
--                   Master_Port: 3306
--                 Connect_Retry: 60
--               Master_Log_File: mysql-bin-changelog.000004
--           Read_Master_Log_Pos: 2324
--                Relay_Log_File: relaylog.000004
--                 Relay_Log_Pos: 279
--         Relay_Master_Log_File: mysql-bin-changelog.000004
--              Slave_IO_Running: Yes
--             Slave_SQL_Running: No
--               Replicate_Do_DB: test
--           Replicate_Ignore_DB:
--            Replicate_Do_Table:
--        Replicate_Ignore_Table:
--       Replicate_Wild_Do_Table:
--   Replicate_Wild_Ignore_Table: mysql.%
--                    Last_Errno: 1062
--                    Last_Error: Coordinator stopped because there were error(s) in the worker(s). The most recent failure being: Worker 1 failed executing transaction 'ANONYMOUS' at source log mysql-bin-changelog.000004, end_log_pos 2293. See error log and/or performance_schema.replication_applier_status_by_worker table for more details about this failure or others, if any.
--                  Skip_Counter: 0
--           Exec_Master_Log_Pos: 2046
--               Relay_Log_Space: 882
--               Until_Condition: None
--                Until_Log_File:
--                 Until_Log_Pos: 0
--            Master_SSL_Allowed: Yes
--            Master_SSL_CA_File:
--            Master_SSL_CA_Path:
--               Master_SSL_Cert:
--             Master_SSL_Cipher:
--                Master_SSL_Key:
--         Seconds_Behind_Master: NULL
-- Master_SSL_Verify_Server_Cert: No
--                 Last_IO_Errno: 0
--                 Last_IO_Error:
--                Last_SQL_Errno: 1062
--                Last_SQL_Error: Coordinator stopped because there were error(s) in the worker(s). The most recent failure being: Worker 1 failed executing transaction 'ANONYMOUS' at source log mysql-bin-changelog.000004, end_log_pos 2293. See error log and/or performance_schema.replication_applier_status_by_worker table for more details about this failure or others, if any.
--                          ...snip...
```
