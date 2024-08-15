# Amazon Aurora Global Database

```sh
aws-vault exec --region ap-northeast-1 profile -- ssh ec2-user@i-11111111111111111
aws-vault exec --region ap-northeast-3 profile -- ssh ec2-user@i-22222222222222222

sudo dnf install -y postgresql15

PGPASSWORD=password psql -h rds.local -U test
```

```sql
create table t (id serial not null, v text);
insert into t (v) values ('テスト');
select * from t;
```

## 作成順序

以下のどちらの順番でも可能。

- グローバルデータベースを作成 → その一部としてクラスターを作成
- リージョナルクラスター作成 → そのクラスターをソースとしてグローバルデータベースを作成

グローバルデータベースとクラスターをそれぞれ作成後、グローバルデータベースにクラスターを追加するようなことはできない。

## aws_rds_global_cluster.database_name

クラスターを先に作成する場合、aws_rds_global_cluster.database_name は指定できない。

> When creating global cluster from existing db cluster, value for databaseName should not be specified since it will be inherited from source cluster

逆に、グローバルデータベースを先に作成する場合、最初に作成されるデータベースは、
その後に作成するクラスターの database_name になるようで、
グローバルデータベースで database_name を指定していても何の効果も無いような気がする。

aws_rds_global_cluster.database_name が何のためにあるのか、判らない？

## セカンダリ database_name, username,password

セカンダリクラスタの作成時は database_name,master_username,master_password は指定できない。
これらはプライアンリと同値にしかならないため。

> InvalidParameterCombination: Cannot specify database name for cross region replication cluster
> InvalidParameterCombination: Cannot specify user name for cross region replication cluster
> InvalidParameterCombination: Cannot specify password for cross region replication cluster
