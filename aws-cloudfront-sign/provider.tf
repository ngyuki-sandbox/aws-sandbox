
provider "aws" {
  region              = var.region
  allowed_account_ids = var.allowed_account_ids
}

provider "aws" {
  alias               = "cloudfront"
  region              = "us-east-1"
  allowed_account_ids = var.allowed_account_ids
}
