
variable "name" {
  type    = string
  default = "sandbox-lmvm"
}

variable "default_tags" {
  type = map(string)
  default = {
    Project = "sandbox-lambda-microvm"
  }
}

variable "port" {
  type    = number
  default = 8080
}

data "aws_region" "main" {}
