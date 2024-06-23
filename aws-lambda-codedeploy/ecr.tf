
resource "aws_ecr_repository" "main" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = var.name
  }
}

data "aws_ecr_authorization_token" "main" {}

resource "terraform_data" "dummy_image_push" {
  provisioner "local-exec" {
    command = <<-EOF
      docker login -u AWS -p ${data.aws_ecr_authorization_token.main.password} ${aws_ecr_repository.main.repository_url} &&\
      docker pull alpine:latest &&\
      docker tag alpine:latest ${aws_ecr_repository.main.repository_url}:latest &&\
      docker push ${aws_ecr_repository.main.repository_url}:latest
    EOF
  }
}
