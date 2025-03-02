
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    gitlab = {
      source = "gitlabhq/gitlab"
    }
  }
}

provider "aws" {
  default_tags {
    tags = var.default_tags
  }
}

provider "gitlab" {
  base_url = var.gitlab_url
}
