
variable "name" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "vpce_ids" {
  type = list(string)
}

variable "certificate_arn" {
  type = string
}

variable "domain_name" {
  type = string
}
