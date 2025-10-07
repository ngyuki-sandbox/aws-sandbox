
resource "aws_ecs_cluster" "main" {
  name = var.name
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  cpu                      = 2048
  memory                   = 4096
  skip_destroy             = false

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = data.aws_ecr_image.main.image_uri
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      command = [
        "node",
        "main.mjs",
      ]
      environment = [
        {
          name  = "ELASTICACHE_HOST"
          value = local.elasticache_host
        },
        {
          name  = "ELASTICACHE_TLS"
          value = local.elasticache_tls ? "on" : ""
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = data.aws_region.main.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
