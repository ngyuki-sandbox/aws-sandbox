
resource "aws_ecs_task_definition" "main" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      "name" : "amazon-linux",
      "image" : "amazonlinux:latest",
      "essential" : true,
      "command" : ["sleep", "3600"],
      "linuxParameters" : {
        "initProcessEnabled" : true
      },
    }
  ])
}

resource "aws_ecs_cluster" "main" {
  name = var.name
}

resource "aws_ecs_service" "main" {
  name                   = var.name
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.main.arn
  launch_type            = "FARGATE"
  enable_execute_command = true
  desired_count          = 1

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
  }
}
