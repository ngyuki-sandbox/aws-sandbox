################################################################################
# AWS
################################################################################

provider "aws" {
  region = local.env.region

  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform"
  }
}
