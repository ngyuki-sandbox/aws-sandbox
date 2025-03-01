
resource "aws_codeconnections_host" "main" {
  name              = var.gitlab_url
  provider_endpoint = var.gitlab_url
  provider_type     = "GitLabSelfManaged"
}

resource "aws_codeconnections_connection" "main" {
  name     = var.gitlab_url
  host_arn = aws_codeconnections_host.main.arn

  lifecycle {
    ignore_changes = [provider_type]
  }
}
