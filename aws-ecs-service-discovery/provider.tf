
provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project = "aws-sandbox/aws-ecs-service-connect"
    }
  }
}
