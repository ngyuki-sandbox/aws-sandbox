
variable "name" {
  type    = string
  default = "aws-ecr-cache-from-to"
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Project = "aws-sandbox"
      Path    = basename(abspath(path.module))
    }
  }
}

resource "aws_ecr_repository" "app" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "タグなしイメージを 1 日で削除"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}
