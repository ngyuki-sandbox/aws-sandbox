
resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = var.name
  destination = "extended_s3"

  kinesis_source_configuration {
    role_arn           = aws_iam_role.firehose.arn
    kinesis_stream_arn = aws_kinesis_stream.stream.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose.arn
    bucket_arn         = aws_s3_bucket.s3.arn
    buffering_size     = 1
    buffering_interval = 60
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }

    s3_backup_mode = "Disabled"
  }
}

resource "aws_cloudwatch_log_group" "firehose" {
  name              = "${var.name}-firehose-log"
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
        "Effect" : "Allow",
        "Action" : [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ],
        "Resource" : aws_kinesis_stream.stream.arn,
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_stream.firehose.arn}:*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "firehose_self" {
  role = aws_iam_role.firehose.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        "Resource" : aws_kinesis_firehose_delivery_stream.firehose.arn
      },
    ]
  })
}
