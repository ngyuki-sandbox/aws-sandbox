#!/bin/bash

set -eux

count=10
loop=$1
time=$2

{
  echo "loop=$loop time=$time"
  sleep 1

  tfoutput="$(terraform -chdir=terraform/ output -json)"

  ecr_repository_name="$(jq .ecr_repository_name.value -r <<<"$tfoutput")"
  ecr_repository_url="$(jq .ecr_repository_url.value -r <<<"$tfoutput")"
  ecs_cluster_name="$(jq .ecs_cluster_name.value -r <<<"$tfoutput")"
  ecs_task_definition="$(jq .ecs_task_definition.value -r <<<"$tfoutput")"
  log_group_name="$(jq .log_group_name.value -r <<<"$tfoutput")"
  subnet_ids="$(jq .subnet_ids.value -r <<<"$tfoutput")"
  security_group_id="$(jq .security_group_id.value -r <<<"$tfoutput")"

  mkdir -p .build
  date=$(date +%Y%m%dT%H%M%S)

  jq -n --arg time "$time" --arg date "$date" '{
    "containerOverrides":[{
      "name":"app",
      "environment": [
        { "name": "TIME", "value": $time },
        { "name": "DATE", "value": $date }
      ]
    }]
  }' > .build/overrides.json


  jq -n --arg subnet_ids "$subnet_ids" --arg security_group_id "$security_group_id" '{
    "awsvpcConfiguration":{
      "subnets":$subnet_ids|split(","),
      "securityGroups":[$security_group_id],
      "assignPublicIp":"ENABLED"
    }
  }' > .build/network.json

  for x in $(seq "$loop"); do
    sleep 0.1
    (
      while ! aws --no-cli-pager ecs run-task \
        --cluster "$ecs_cluster_name" \
        --count "$count" \
        --launch-type FARGATE \
        --task-definition "$ecs_task_definition" \
        --network-configuration file://.build/network.json \
        --overrides file://.build/overrides.json \
      ; do
        sleep 1
      done
    ) &
  done
  aws logs tail "$log_group_name" --follow --format short
}
