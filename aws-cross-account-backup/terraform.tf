
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias  = "source"
  region = var.region
  assume_role {
    role_arn = var.source_role_arn
  }
  default_tags {
    tags = var.default_tags
  }
}

provider "aws" {
  alias  = "destination"
  region = var.region
  assume_role {
    role_arn = var.destination_role_arn
  }
  default_tags {
    tags = var.default_tags
  }
}

provider "aws" {
  alias  = "mgmt"
  region = var.region
  default_tags {
    tags = var.default_tags
  }
}
