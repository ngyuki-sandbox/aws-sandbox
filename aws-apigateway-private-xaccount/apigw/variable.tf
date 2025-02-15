
variable "name" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "vpc_ids" {
  type = list(string)
}

variable "vpce_ids" {
  type = list(string)
}
