# aws-ecs-ssm-port-forwarding

- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html
- https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task-iam-roles.html

## ECS Exec

```sh
cluster_name="$(terraform output --json | jq .cluster_name.value -r)"
container_name="$(terraform output --json | jq .container_name.value -r)"
task_arn="$(aws ecs list-tasks --cluster "$cluster_name" | jq .taskArns[0] -r)"

aws ecs execute-command \
    --cluster "$cluster_name" \
    --task "$task_arn" \
    --container "$container_name" \
    --interactive \
    --command "/bin/sh"
```

## Port forwarding

```sh
task_id=${task_arn##*/}
runtime_id="$(aws ecs describe-tasks --cluster "$cluster_name" --tasks "$task_arn" | jq .tasks[0].containers[0].runtimeId -r)"
rds_host="$(terraform output --json | jq .rds_host.value -r)"

aws ssm start-session \
    --target "ecs:${cluster_name}_${task_id}_${runtime_id}" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{
        \"portNumber\":[\"3306\"],
        \"localPortNumber\":[\"3306\"],
        \"host\":[\"$rds_host\"]
    }"
```
