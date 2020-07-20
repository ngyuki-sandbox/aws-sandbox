################################################################################
# AWS

terraform {
  required_version = ">=0.12.0"
}

provider aws {
  region = "ap-northeast-1"
}

variable key_name {}

variable tag {
  default = "datasync-example"
}

################################################################################
# IAM Role datasync for s3

resource aws_iam_role datasync_s3 {
  name = "${var.tag}-datasync_s3"

  assume_role_policy = <<-EOS
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "datasync.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
    }
  EOS
}

resource aws_iam_role_policy datasync_s3 {
  name = "${var.tag}-datasync_s3"
  role = aws_iam_role.datasync_s3.id

  policy = <<-EOS
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "s3:GetBucketLocation",
                    "s3:ListBucket",
                    "s3:ListBucketMultipartUploads",
                    "s3:HeadBucket"
                ],
                "Effect": "Allow",
                "Resource": "${aws_s3_bucket.bucket.arn}"
            },
            {
                "Action": [
                    "s3:AbortMultipartUpload",
                    "s3:DeleteObject",
                    "s3:GetObject",
                    "s3:ListMultipartUploadParts",
                    "s3:PutObject"
                ],
                "Effect": "Allow",
                "Resource": "${aws_s3_bucket.bucket.arn}/*"
            }
        ]
    }
  EOS
}

################################################################################
# VPC

data aws_vpc vpc {
  default = true
}

data aws_subnet subnet_a {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "ap-northeast-1a"

}

data aws_security_group default {
  vpc_id = data.aws_vpc.vpc.id
  name   = "default"
}

################################################################################
# EFS

resource aws_efs_file_system efs {
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  tags = {
    Name = "${var.tag}-efs"
  }
}

resource aws_efs_mount_target efs_a {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.subnet_a.id
  security_groups = [data.aws_security_group.default.id]
}

################################################################################
# S3

resource aws_s3_bucket bucket {
  bucket_prefix = "${var.tag}-bucket-"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "${var.tag}-bucket"
  }
}

################################################################################
# EC2

data aws_ssm_parameter ami_amazon_linux {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data aws_iam_instance_profile ec2 {
  name = "AmazonSSMRoleForInstancesQuickSetup"
}

resource aws_instance amazon_linux {
  ami                    = data.aws_ssm_parameter.ami_amazon_linux.value
  instance_type          = "t2.nano"
  key_name               = var.key_name
  subnet_id              = data.aws_subnet.subnet_a.id
  vpc_security_group_ids = [data.aws_security_group.default.id]
  iam_instance_profile   = data.aws_iam_instance_profile.ec2.name

  user_data = <<-EOS
    #!/bin/bash
    set -eux
    yum install -y amazon-efs-utils
    mount -t efs -o tls ${aws_efs_mount_target.efs_a.file_system_id}:/ /mnt
  EOS

  tags = {
    Name = "${var.tag}-amazon_linux"
  }
}

output amazon_linux {
  value = {
    instance_id = aws_instance.amazon_linux.id
    public_ip   = aws_instance.amazon_linux.public_ip
  }
}

data aws_ssm_parameter ami_datasync_agent {
  name = "/aws/service/datasync/ami"
}

resource aws_instance datasync_agent {
  ami                    = data.aws_ssm_parameter.ami_datasync_agent.value
  instance_type          = "m5.2xlarge"
  key_name               = var.key_name
  subnet_id              = data.aws_subnet.subnet_a.id
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "${var.tag}-datasync_agent"
  }
}

################################################################################
# DataSync

resource aws_datasync_agent datasync {
  name       = "${var.tag}-datasync"
  ip_address = aws_instance.datasync_agent.public_ip

  tags = {
    Name = "${var.tag}-agent"
  }
}

resource aws_datasync_location_nfs location_nfs {
  server_hostname = aws_efs_mount_target.efs_a.ip_address
  subdirectory    = "/"

  on_prem_config {
    agent_arns = [aws_datasync_agent.datasync.arn]
  }

  tags = {
    Name = "${var.tag}-nfs"
  }
}

resource aws_datasync_location_s3 location_s3 {
  s3_bucket_arn = aws_s3_bucket.bucket.arn
  subdirectory  = "/sync"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3.arn
  }

  tags = {
    Name = "${var.tag}-s3"
  }
}

resource aws_datasync_task efs_to_s3 {
  name = "${var.tag}-efs_to_s3"

  source_location_arn      = aws_datasync_location_nfs.location_nfs.arn
  destination_location_arn = aws_datasync_location_s3.location_s3.arn
  cloudwatch_log_group_arn = trimsuffix(aws_cloudwatch_log_group.efs_to_s3.arn, ":*")

  options {
    bytes_per_second       = -1
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    gid                    = "INT_VALUE"
    uid                    = "INT_VALUE"
    posix_permissions      = "PRESERVE"
    preserve_deleted_files = "REMOVE"
    preserve_devices       = "NONE"
    verify_mode            = "ONLY_FILES_TRANSFERRED"
  }
}

################################################################################
# Cloudwatch Log

resource aws_cloudwatch_log_group efs_to_s3 {
  name              = "/${var.tag}/efs-to-s3"
  retention_in_days = 1
}

resource aws_cloudwatch_log_resource_policy efs_to_s3 {
  policy_name     = "${var.tag}-efs_to_s3"
  policy_document = <<-EOS
    {
        "Statement": [
            {
                "Sid": "DataSyncLogsToCloudWatchLogs",
                "Effect": "Allow",
                "Action": [
                    "logs:PutLogEvents",
                    "logs:CreateLogStream"
                ],
                "Principal": {
                    "Service": "datasync.amazonaws.com"
                },
                "Resource": "*"
            }
        ],
        "Version": "2012-10-17"
    }
    EOS
}
