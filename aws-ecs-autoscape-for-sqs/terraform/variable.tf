
variable "name" {
  type    = string
  default = "example"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "default_tags" {
  type = map(string)
  default = {
    Project = "example"
  }
}
