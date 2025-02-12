
provider "aws" {
  region = "ap-northeast-1"
  alias  = "tokyo"
}

provider "aws" {
  region = "ap-northeast-3"
  alias  = "osaka"
}

module "tokyo" {
  source = "./ec2"
  providers = {
    aws = aws.tokyo
  }
  name = "tokyo"
}

module "osaka" {
  source = "./ec2"
  providers = {
    aws = aws.osaka
  }
  name = "osaka"
}

output "main" {
  value = {
    tokyo = module.tokyo
    osaka = module.osaka
  }
}
