# クロスアカウント SNS/SQS

## SQS 所有者がサブスクライブ

- SNS トピックポリシーで SQS 側 IAM Role からの sns:Subscribe を許可する
- SQS キューポリシーに sqs:SendMessage が必要なのは同じ

## SNS 所有者がサブスクライブ

- SNS トピックポリシーは不要
- SNS でサブスクライブ登録後に SQS のメッセージから URL を取り出してサブスクライブ完了する
- SQS キューポリシーに sqs:SendMessage が必要なのは同じ
ｆ
