// vars.json は Terraform が生成して zip に同梱する
local vars = import 'vars.json';

{
  region: vars.region,
  cluster: vars.cluster,
  service: vars.service,
  task_definition: 'ecs-task-def.jsonnet',
  timeout: '20m',

  // サービスは Terraform で管理するので service_definition は指定しない

  codedeploy: {
    application_name: vars.codedeployApplication,
    deployment_group_name: vars.codedeployGroup,
  },
}
