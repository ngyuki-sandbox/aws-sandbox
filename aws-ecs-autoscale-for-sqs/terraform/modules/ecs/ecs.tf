
data "aws_region" "main" {}

resource "aws_ecs_cluster" "main" {
  name = var.name
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      "name" : "worker",
      "image" : "${aws_ecr_repository.main.repository_url}:${terraform_data.image.output}",
      "essential" : true,
      "environment" : [for k, v in var.environments : { "name" : k, "value" : v }],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : data.aws_region.main.name,
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-stream-prefix" : terraform_data.image.output,
        }
      },
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = var.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  launch_type     = "FARGATE"

  desired_count                      = 0
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
