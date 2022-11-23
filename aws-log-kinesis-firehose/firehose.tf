resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = var.name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = aws_s3_bucket.s3.arn
    buffer_size         = 1
    buffer_interval     = 60
    compression_format  = "UNCOMPRESSED"

    processing_configuration {
      enabled = true
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = aws_lambda_function.lambda.arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "1"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }

    s3_backup_mode = "Disabled"
  }
}

resource "aws_cloudwatch_log_group" "firehose" {
  name = "${var.name}-firehose-log"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "firehose" {
  log_group_name = aws_cloudwatch_log_group.firehose.name
  name           = "${var.name}-firehose-log"
}

resource "aws_iam_role" "firehose" {
  name = "${var.name}-firehose"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "firehose.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose" {
  role = aws_iam_role.firehose.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.s3.arn}",
          "${aws_s3_bucket.s3.arn}/*"
        ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "lambda:InvokeFunction",
              "lambda:GetFunctionConfiguration",
          ],
          "Resource": aws_lambda_function.lambda.arn,
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "${aws_cloudwatch_log_stream.firehose.arn}:*",
        ]
      },
    ]
  })
}
