
provider "aws" {
  region              = var.region
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.defailt_tags
  }
}

provider "aws" {
  alias               = "cloudfront"
  region              = "us-east-1"
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.defailt_tags
  }
}
