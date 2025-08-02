
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

  container_definitions = jsonencode([
    {
      "name" : "app",
      "image" : "php:alpine",
      "essential" : true,
      "environment" : [
        {
          "name" : "APP_ENV",
          "value" : "dev"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.ecs.name,
          "awslogs-region" : data.aws_region.main.region,
          "awslogs-stream-prefix" : "app"
        }
      }
    }
  ])
}
