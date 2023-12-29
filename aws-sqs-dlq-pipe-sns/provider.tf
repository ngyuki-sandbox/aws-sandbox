
provider "aws" {
  region = var.region

  default_tags {
    tags = var.default_tags
  }

  allowed_account_ids = var.allowed_account_ids
}
