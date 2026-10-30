
data "aws_region" "current" {}

locals {
  container_name = "app"
  container_port = 80
}

resource "aws_ecs_cluster" "main" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/${var.name}/ecs"
  retention_in_days = 1
}

# サービス作成用の初期タスク定義
# 以降は ecspresso が同じファミリーに新しいリビジョンを登録する
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
      name      = local.container_name
      image     = "public.ecr.aws/docker/library/nginx:alpine"
      essential = true
      command = [
        "sh", "-c",
        "echo \"$MESSAGE\" > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'",
      ]
      environment = [
        { name = "MESSAGE", value = "initial (terraform)" },
      ]
      portMappings = [
        {
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "main" {
  name                   = var.name
  cluster                = aws_ecs_cluster.main.arn
  task_definition        = aws_ecs_task_definition.main.arn
  desired_count          = var.desired_count
  enable_execute_command = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = aws_subnet.main[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main["blue"].arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  depends_on = [aws_lb_listener.prod]

  # デプロイ後は ecspresso と CodeDeploy がタスク定義とターゲットグループを切り替える
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
    ]
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs"
  description = "${var.name}-ecs"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = local.container_port
  to_port                      = local.container_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

################################################################################
# IAM

resource "aws_iam_role" "execution" {
  name = "${var.name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${var.name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# ECS Exec 用
resource "aws_iam_role_policy" "task" {
  name = "ecs-exec"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      Resource = "*"
    }]
  })
}
