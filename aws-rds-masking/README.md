# RDS スナップショットをマスクしてリストア

以下の一連の処理を Terraform で自動化します。

- スナップショットから RDS をリストア
- Lambda を実行してデータのマスキング
- Route53 の CNAME レコードの切り替え