
provider "aws" {
  region              = "ap-northeast-1"
  alias               = "tky"
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = merge(var.default_tags, { Env = "tky" })
  }
}

provider "aws" {
  region              = "ap-northeast-3"
  alias               = "osk"
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = merge(var.default_tags, { Env = "osk" })
  }
}
