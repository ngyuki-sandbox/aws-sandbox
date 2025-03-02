
data "aws_region" "main" {}

data "aws_caller_identity" "main" {}

data "gitlab_project" "main" {
  path_with_namespace = var.gitlab_repo
}

resource "gitlab_project_hook" "main" {
  name                    = "aws:${data.aws_region.main.name}:${data.aws_caller_identity.main.account_id}:${var.name}"
  project                 = data.gitlab_project.main.id
  url                     = aws_lambda_function_url.main.function_url
  enable_ssl_verification = true
  push_events             = false
  job_events              = true
  custom_headers = [
    {
      key   = "x-secret-token"
      value = random_password.token.result
    },
  ]
}

resource "gitlab_project_access_token" "main" {
  project      = data.gitlab_project.main.id
  name         = "aws:${data.aws_region.main.name}:${data.aws_caller_identity.main.account_id}:${var.name}"
  access_level = "maintainer"
  scopes       = ["api"]
  rotation_configuration = {
    expiration_days    = 365
    rotate_before_days = 180
  }
}

resource "gitlab_user_runner" "main" {
  project_id      = data.gitlab_project.main.id
  runner_type     = "project_type"
  description     = "aws:${data.aws_region.main.name}:${data.aws_caller_identity.main.account_id}:${var.name}"
  locked          = true
  untagged        = false
  tag_list        = var.runner_tags
  maximum_timeout = 600
}
