# aws-ecs-events

## ECS Deployment State Change

Chatbot の素だと次のような内容。クラスタ名やサービス名が無く非常に判りずらい。

```
ECS Deployment State Change | ap-northeast-1 | Account: 999999999999

ECS deployment ecs-svc/6177963417134325488 in progress.

Deployment ID: ecs-svc/6177963417134325488
Event type: INFO
Event name: SERVICE_DEPLOYMENT_IN_PROGRESS
Updated at: Tue, 18 Feb 2025 00:17:22 GMT
```

ペイロードに cluster や service の arn は入っているのだけど・・

```json
{
    "version": "0",
    "id": "342d35fb-19b8-9ef6-bbc0-9abd3ac4495f",
    "detail-type": "ECS Deployment State Change",
    "source": "aws.ecs",
    "account": "999999999999",
    "time": "2025-02-18T00:17:22Z",
    "region": "ap-northeast-1",
    "resources": [
        "arn:aws:ecs:ap-northeast-1:999999999999:service/example-cluster/example-service"
    ],
    "detail": {
        "eventType": "INFO",
        "eventName": "SERVICE_DEPLOYMENT_IN_PROGRESS",
        "clusterArn": "arn:aws:ecs:ap-northeast-1:999999999999:cluster/example-cluster",
        "deploymentId": "ecs-svc/6177963417134325488",
        "updatedAt": "2025-02-18T00:17:22Z",
        "reason": "ECS deployment ecs-svc/6177963417134325488 in progress."
    }
}
```

入力トランスフォーマーで reason を書き換えるとか？

```
  input_transformer {
    input_paths = {
      "version"             = "$.version",
      "id"                  = "$.id",
      "detail-type"         = "$.detail-type"
      "source"              = "$.source",
      "account"             = "$.account",
      "time"                = "$.time",
      "region"              = "$.region",
      "resource"            = "$.resources[0]",
      "detail-eventType"    = "$.detail.eventType"
      "detail-eventName"    = "$.detail.eventName"
      "detail-clusterArn"   = "$.detail.clusterArn"
      "detail-deploymentId" = "$.detail.deploymentId"
      "detail-reason"       = "$.detail.reason"
      "detail-updatedAt"    = "$.detail.updatedAt"
    }
    input_template = <<-EOT
      {
        "version": "<version>",
        "id": "<id>",
        "detail-type": "<detail-type>",
        "source": "<source>",
        "account": "<account>",
        "time": "<time>",
        "region": "<region>",
        "resources": ["<resource>"],
        "detail": {
            "clusterArn": "<detail-clusterArn>",
            "eventType": "<detail-eventType>",
            "eventName": "<detail-eventName>",
            "deploymentId": "<detail-deploymentId>",
            "updatedAt": "<detail-updatedAt>",
            "reason": "<detail-reason>\n\n*Service*\r${aws_ecs_service.main.name}"
        }
      }
    EOT
  }
```

あるいは入力トランスフォーマで通知に書き換えるか・・eventName が3パターンあるので emoji を分けようとすると3パターンルールを定義する必要があるが・・
