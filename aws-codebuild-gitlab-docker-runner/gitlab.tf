
data "aws_region" "main" {}

data "aws_caller_identity" "main" {}

data "gitlab_metadata" "main" {}

data "gitlab_project" "main" {
  path_with_namespace = var.gitlab_repo
}

resource "gitlab_project_hook" "main" {
  name                    = "aws:${data.aws_region.main.region}:${data.aws_caller_identity.main.account_id}:${var.name}"
  project                 = data.gitlab_project.main.id
  url                     = aws_lambda_function_url.main.function_url
  enable_ssl_verification = true
  push_events             = false
  job_events              = true
  signing_token           = "whsec_${random_bytes.signing_token.base64}"
}

resource "gitlab_project_access_token" "main" {
  project      = data.gitlab_project.main.id
  name         = "aws:${data.aws_region.main.region}:${data.aws_caller_identity.main.account_id}:${var.name}"
  access_level = "maintainer"
  scopes       = ["read_api"]
  rotation_configuration = {
    expiration_days    = 365
    rotate_before_days = 180
  }
}

moved {
  from = gitlab_user_runner.main
  to   = gitlab_user_runner.docker
}

resource "gitlab_user_runner" "docker" {
  project_id      = data.gitlab_project.main.id
  runner_type     = "project_type"
  description     = "aws:${data.aws_region.main.region}:${data.aws_caller_identity.main.account_id}:${var.name}:docker"
  locked          = true
  untagged        = false
  tag_list        = var.runner_docker_tags
  maximum_timeout = 600
}

resource "gitlab_user_runner" "shell" {
  project_id      = data.gitlab_project.main.id
  runner_type     = "project_type"
  description     = "aws:${data.aws_region.main.region}:${data.aws_caller_identity.main.account_id}:${var.name}:shell"
  locked          = true
  untagged        = false
  tag_list        = var.runner_shell_tags
  maximum_timeout = 600
}
