
resource "aws_ecr_repository" "main" {
  name                 = var.name
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}

data "aws_ecr_authorization_token" "main" {}

resource "terraform_data" "image" {
  input = formatdate("'v'YYYYMMDD'T'hhmmss", timeadd(plantimestamp(), "9h"))

  provisioner "local-exec" {
    working_dir = "${path.module}/../../../app/"
    command     = <<-EOF
      docker login -u AWS -p "$TOKEN" "$IMAGE_REPO" &&\
      docker buildx build . -t "$IMAGE_URL" --push --provenance=false
    EOF
    environment = {
      TOKEN      = nonsensitive(data.aws_ecr_authorization_token.main.password)
      IMAGE_REPO = aws_ecr_repository.main.repository_url
      IMAGE_URL  = "${aws_ecr_repository.main.repository_url}:${self.input}"
    }
  }

  lifecycle {
    ignore_changes = [input]
  }
}
