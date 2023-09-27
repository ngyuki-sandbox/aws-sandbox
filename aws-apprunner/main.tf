
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "allowed_account_ids" {
  type = list(string)
}

variable "default_tags" {
  type = map(string)
}

provider "aws" {
  region              = var.region
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.default_tags
  }
}

resource "aws_apprunner_service" "main" {
  service_name = var.name

  source_configuration {
    image_repository {
      image_identifier      = "public.ecr.aws/aws-containers/hello-app-runner:latest"
      image_repository_type = "ECR_PUBLIC"
      image_configuration {
        port                          = "8080"
        runtime_environment_variables = {}
      }
    }
    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu    = "256"
    memory = "512"
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
    egress_configuration {
      egress_type = "DEFAULT"
    }
  }

  tags = {
    Name = var.name
  }
}
