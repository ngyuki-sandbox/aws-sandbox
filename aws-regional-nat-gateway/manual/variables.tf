
variable "name" {
  type    = string
  default = "sandbox-rngw"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
