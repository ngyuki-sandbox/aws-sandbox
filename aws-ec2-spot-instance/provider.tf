
provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.default_tags
  }
}
