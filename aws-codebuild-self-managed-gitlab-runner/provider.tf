
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.91.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = var.default_tags
  }
}
