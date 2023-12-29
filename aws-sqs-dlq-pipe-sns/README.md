# aws-sqs-dlq-notification

SQS のデッドレターを EventBridge Pipes 経由の SNS で通知してみる。

```sh
export SQS_QUEUE_URL="$(terraform output --json | jq .sqs_queue_url.value -r)"

aws sqs send-message --queue-url "$SQS_QUEUE_URL" --message-body test1
aws sqs receive-message --queue-url "$SQS_QUEUE_URL"
```
