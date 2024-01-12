# aws-apigateway-kinesis-stream-firehose-lambda

```
API Gateway -> Kinesis Stream
    -> Kinesis Firehose -> S3
    -> Lambda
```

```sh
terraform init
terraform apply

# バケットをクリア
aws s3 rm --recursive "s3://$(terraform output -raw s3_bucket)"

# Lambda ログを監視
aws logs tail "$(terraform output -raw lambda_log_group)" --follow --format short

# CLI でレコード送信
aws kinesis put-record --stream-name "$(terraform output -raw stream_name)" \
    --data $(echo test | base64) --partition-key test

# API でレコード送信
curl -X POST "$(terraform output -raw api_invoke_url)/stream" \
  -H content-type:application/json \
  -d '{"Data":{"abc":123},"PartitionKey":"test"}'

# s3 のオブジェクト確認
aws s3 ls --recursive "s3://$(terraform output -raw s3_bucket)"
```
