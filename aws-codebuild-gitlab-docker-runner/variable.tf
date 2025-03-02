
variable "name" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "gitlab_url" {
  type = string
}

variable "gitlab_repo" {
  type = string
}

variable "runner_tags" {
  type = list(string)
}
