# [AWS]Amazon RDS for PostgreSQL 14.2 から Aurora PostgreSQL 13.6 へのレプリケーション

## 参考

- https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html
- https://www.postgresql.jp/document/13/html/logical-replication.html
- https://github.com/2ndQuadrant/pglogical
- https://aws.amazon.com/jp/blogs/database/part-2-upgrade-your-amazon-rds-for-postgresql-database-using-the-pglogical-extension/

```sh
ssh i-xxxxxxxxxxxxxxxxx -l ec2-user
```

```sql
PGPASSWORD=password psql test -h rds.local.test -U postgres

CREATE TABLE t (
    id  INT PRIMARY KEY,
    val INT
);

INSERT INTO t VALUES (1, 1);
SELECT * FROM t;
CREATE PUBLICATION pub;
ALTER PUBLICATION pub SET TABLE t;
\q
```

```sql
PGPASSWORD=password psql test -h aurora.local.test -U postgres

CREATE TABLE t (
    id  INT PRIMARY KEY,
    val INT
);

SELECT * FROM t;
CREATE SUBSCRIPTION sub CONNECTION 'host=rds.local.test port=5432 dbname=test user=postgres password=password' PUBLICATION pub;
SELECT * FROM t;
```
