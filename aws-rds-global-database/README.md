# Amazon Aurora Global Database

```sh
aws ssm start-session --region ap-northeast-1 --target "$(terraform output -raw tokyo_instance_id)"
aws ssm start-session --region ap-northeast-3 --target "$(terraform output -raw osaka_instance_id)"

sudo dnf install -y postgresql18
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

## セカンダリの database_name,username,password

セカンダリクラスタの作成時は database_name,master_username,master_password は指定できない。
これらはプライマリクラスタと同値にしかならないため。

> InvalidParameterCombination: Cannot specify database name for cross region replication cluster
> InvalidParameterCombination: Cannot specify user name for cross region replication cluster
> InvalidParameterCombination: Cannot specify password for cross region replication cluster

## 検証系などでコスト削減

- セカンダリクラスタはヘッドレス化できるが、プライマリクラスタは最低でも1つのライターインスタンスが必要
- セカンダリクラスタが存在する場合（ヘッドレスでも）、プライマリクラスタを停止したりヘッドレス化したりできない
- セカンダリクラスタは削除可能なので、シングルクラスタに戻したうえで、プライマリクラスタを停止やヘッドレス化は可能
