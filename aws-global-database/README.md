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
