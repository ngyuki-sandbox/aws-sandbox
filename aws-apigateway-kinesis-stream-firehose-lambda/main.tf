
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = var.default_tags
  }
}

data "aws_region" "main" {}

variable "name" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

output "stream_name" {
  value = aws_kinesis_stream.stream.name
}

output "lambda_log_group" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "s3_bucket" {
  value = aws_s3_bucket.s3.id
}

output "api_invoke_url" {
  value = aws_api_gateway_stage.api.invoke_url
}
