# Gitlab から ECS へデプロイする実験

## AWS CLI で ECS Run Task を実行

ログを取るのがタスク定義のログ定義から色々やる必要があるようで、ちょっとめんどい。

```sh
aws ecs list-clusters

aws ecs list-services --cluster arn:aws:ecs:ap-northeast-1:XXXXX:cluster/oreore-ecs-gitlab-cluster
# arn:aws:ecs:ap-northeast-1:XXXXX:service/oreore-ecs-gitlab-cluster/oreore-ecs-gitlab-app-service

aws ecs describe-services \
    --cluster arn:aws:ecs:ap-northeast-1:XXXXX:cluster/oreore-ecs-gitlab-cluster \
    --services arn:aws:ecs:ap-northeast-1:XXXXX:service/oreore-ecs-gitlab-cluster/oreore-ecs-gitlab-app-service \
    --query 'services[0].networkConfiguration' | jq . -c
# {"awsvpcConfiguration":{"subnets":["subnet-XXXXX","subnet-XXXXX"],"securityGroups":["sg-XXXXX"],"assignPublicIp":"ENABLED"}}

aws ecs list-tasks --cluster arn:aws:ecs:ap-northeast-1:XXXXX:cluster/oreore-ecs-gitlab-cluster

aws ecs list-task-definitions --query 'taskDefinitionArns[-1:]' --output text
# arn:aws:ecs:ap-northeast-1:XXXXX:task-definition/oreore-ecs-gitlab-app:2

aws ecs describe-task-definition \
    --task-definition arn:aws:ecs:ap-northeast-1:XXXXX:task-definition/oreore-ecs-gitlab-app:2 \
    --query 'taskDefinition.containerDefinitions[0].logConfiguration.options'
# {
#     "awslogs-group": "oreore-ecs-gitlab/ecs",
#     "awslogs-region": "ap-northeast-1",
#     "awslogs-stream-prefix": "app"
# }

aws ecs run-task \
    --task-definition arn:aws:ecs:ap-northeast-1:XXXXX:task-definition/oreore-ecs-gitlab-app:2 \
    --cluster arn:aws:ecs:ap-northeast-1:XXXXX:cluster/oreore-ecs-gitlab-cluster \
    --launch-type FARGATE \
    --network-configuration \
        '{"awsvpcConfiguration":{"subnets":["subnet-XXXXX","subnet-XXXXX"],"securityGroups":["sg-XXXXX"],"assignPublicIp":"ENABLED"}}' \
    --overrides '{
        "containerOverrides": [{
            "name": "app",
            "command": ["ls"]
        }]
    }' \
    --query 'tasks[].taskArn'
# arn:aws:ecs:ap-northeast-1:XXXXX:task/oreore-ecs-gitlab-cluster/XXXXX

aws ecs wait tasks-stopped \
    --cluster arn:aws:ecs:ap-northeast-1:XXXXX:cluster/oreore-ecs-gitlab-cluster \
    --tasks arn:aws:ecs:ap-northeast-1:XXXXX:task/oreore-ecs-gitlab-cluster/XXXXX

aws ecs describe-tasks \
    --cluster arn:aws:ecs:ap-northeast-1:XXXXX:cluster/oreore-ecs-gitlab-cluster \
    --tasks arn:aws:ecs:ap-northeast-1:XXXXX:task/oreore-ecs-gitlab-cluster/XXXXX

aws logs get-log-events \
    --log-group-name oreore-ecs/ecs/app \
    --log-stream-name ecs/app/XXXXX \
    --query 'events[].message' \
    --output text
```

## CodeProject

VPC 内に配置すると Public IP を付与できないので NAT なりプライベートリンクなりがなければ S3 とか ECR にアクセスできない。

```sh
aws codebuild list-projects
# oreore-ecs-gitlab-build

aws codebuild start-build \
    --project-name oreore-ecs-gitlab-build \
    --source-type-override=NO_SOURCE \
    --buildspec-override file://buildspec.yml \
    --query build.id --output text
# oreore-ecs-gitlab-build:XXXXX

aws codebuild batch-get-builds --ids oreore-ecs-gitlab-build:XXXXX --query 'builds[].currentPhase' --output text

aws codebuild batch-get-builds --ids oreore-ecs-gitlab-build:XXXXX \
    --query 'builds[0] | { buildStatus: buildStatus, logs: { groupName: logs.groupName, streamName: logs.streamName } }'

aws logs get-log-events --log-group-name oreore-ecs-gitlab/build --log-stream-name "XXXXX" --query 'events[].message' --output text
```
