
data "aws_region" "main" {}

data "aws_ecr_image" "main" {
  repository_name = aws_ecr_repository.main.name
  image_tag       = "latest"
}
