
variable "name" {
  type    = string
  default = "sandbox-x-backup"
}

variable "default_tags" {
  type = map(string)
  default = {
    Project = "aws-sandbox/aws-cross-account-backup"
  }
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "backup_tag_key" {
  type    = string
  default = "oreore:aws-backup"
}

variable "source_role_arn" {
  type = string
}

variable "destination_role_arn" {
  type = string
}
