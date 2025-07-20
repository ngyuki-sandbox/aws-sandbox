# SQS のメッセージに応じて ECS をゼロからスケーリング

```sh
aws sqs send-message --queue-url "$(terraform -chdir=terraform output -raw sqs_queue_url)" --message-body test
```

## 使用するメトリクス

ApproximateNumberOfMessagesVisible だと実行中に 0 になってしまいそう。
ApproximateNumberOfMessagesDelayed や ApproximateNumberOfMessagesNotVisible との合計で計算すれば大丈夫そうな気はするものの、
ApproximateAgeOfOldestMessage だけで十分。

## スケールアップとダウンのアラームは必要？

adjustment_type=ExactCapacity
で設定する分には、スケーリングポリシーだけ両方作ったうえで、
alarm_actions と ok_actions でそれぞれ指定すれば大丈夫そう。

ステップを多段にすればスケーリングポリシー自体も1つでカバーできそう？
