
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster"
}

resource "aws_ecs_service" "main" {
  name                          = "${var.name}-service"
  cluster                       = aws_ecs_cluster.main.id
  task_definition               = aws_ecs_task_definition.main.arn
  launch_type                   = "FARGATE"
  availability_zone_rebalancing = "ENABLED"
  enable_execute_command        = true

  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = data.aws_subnets.main.ids
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      "name" : "app",
      "image" : "nginx:alpine",
      "essential" : true,
      "environment" : [
        {
          "name" : "APP_ENV",
          "value" : plantimestamp()
        }
      ],
      "portMappings" : [
        {
          "containerPort" : 80,
          "protocol" : "tcp"
        }
      ]
    }
  ])
}
