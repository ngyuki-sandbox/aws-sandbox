
resource "aws_service_discovery_http_namespace" "main" {
  name = var.name
}

resource "aws_ecs_cluster" "main" {
  name = var.name
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
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
      "name" : "app",
      "image" : "public.ecr.aws/docker/library/nginx:latest",
      "essential" : true,
      "portMappings" : [
        {
          "name" : "nginx",
          "containerPort" : 80,
          "protocol" : "tcp",
          "appProtocol" : "http",
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.ecs.name,
          "awslogs-region" : data.aws_region.current.name,
          "awslogs-stream-prefix" : "app"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = var.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  launch_type     = "FARGATE"

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  enable_ecs_managed_tags = true
  enable_execute_command  = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  propagate_tags = "SERVICE"

  service_connect_configuration {
    enabled = true
    service {
      port_name = "nginx"
      client_alias {
        port = 80
      }
    }
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-region"        = data.aws_region.current.name,
        "awslogs-stream-prefix" = "service-connect-proxy"
      }
    }
  }
}
