#--------------------------------------------------------------------------------
# MicroVM Image
#--------------------------------------------------------------------------------

resource "awscc_lambda_microvm_image" "main" {
  name               = var.name
  description        = "${var.name}@sha256:${data.archive_file.main.output_sha256}"
  base_image_arn     = "arn:aws:lambda:${data.aws_region.main.region}:aws:microvm-image:al2023-1"
  base_image_version = "1"
  build_role_arn     = aws_iam_role.main.arn

  code_artifact = {
    uri = "s3://${aws_s3_object.main.bucket}/${aws_s3_object.main.key}"
  }

  cpu_configurations         = [{ architecture = "ARM_64" }]
  resources                  = [{ minimum_memory_in_mi_b = 1024 }]
  additional_os_capabilities = ["ALL"]
  egress_network_connectors  = ["arn:aws:lambda:${data.aws_region.main.region}:aws:network-connector:aws-network-connector:INTERNET_EGRESS"]

  environment_variables = [
    { key = "PORT", value = var.port },
  ]

  hooks = {
    port = var.port
    microvm_image_hooks = {
      ready                       = "ENABLED"
      ready_timeout_in_seconds    = 120
      validate                    = "ENABLED"
      validate_timeout_in_seconds = 30
    }
    microvm_hooks = {
      run                          = "ENABLED"
      run_timeout_in_seconds       = 10
      resume                       = "ENABLED"
      resume_timeout_in_seconds    = 5
      suspend                      = "ENABLED"
      suspend_timeout_in_seconds   = 10
      terminate                    = "ENABLED"
      terminate_timeout_in_seconds = 15
    }
  }

  logging = {
    cloudwatch = {
      log_group = aws_cloudwatch_log_group.main.name
    }
    disabled = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.main,
    aws_s3_object.main,
  ]

  tags = [for k, v in var.default_tags : { key = k, value = v }]
}

#--------------------------------------------------------------------------------
# App Code
#--------------------------------------------------------------------------------

data "archive_file" "main" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/tmp/app.zip"
}

resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-"
  force_destroy = true
}

resource "aws_s3_object" "main" {
  bucket        = aws_s3_bucket.main.id
  key           = "app.zip"
  source        = data.archive_file.main.output_path
  etag          = data.archive_file.main.output_md5
  force_destroy = true
}

#--------------------------------------------------------------------------------
# IAM
#--------------------------------------------------------------------------------

resource "aws_iam_role" "main" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "main" {
  name = var.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

#--------------------------------------------------------------------------------
# Logs
#--------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda-microvms/${var.name}"
  retention_in_days = 3
}
