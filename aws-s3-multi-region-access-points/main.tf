
module "tky" {
  source                      = "./s3"
  providers                   = { aws = aws.tky }
  name                        = "${var.project}-tky"
  replication_role_arn        = aws_iam_role.main.arn
  replication_destination_arn = module.osk.bucket_arn
}

module "osk" {
  source                      = "./s3"
  providers                   = { aws = aws.osk }
  name                        = "${var.project}-osk"
  replication_role_arn        = aws_iam_role.main.arn
  replication_destination_arn = module.tky.bucket_arn
}

resource "aws_iam_role" "main" {
  name = "${var.project}-s3-replication"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "s3.amazonaws.com",
            "batchoperations.s3.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "main" {
  role = aws_iam_role.main.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        "Resource" : [
          module.tky.bucket_arn,
          module.osk.bucket_arn,
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateDelete",
          "s3:ReplicateObject",
          "s3:ReplicateTags",
        ],
        "Resource" : [
          "${module.tky.bucket_arn}/*",
          "${module.osk.bucket_arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3control_multi_region_access_point" "main" {
  provider = aws.tky
  details {
    name = var.project
    region {
      bucket = module.tky.bucket
    }
    region {
      bucket = module.osk.bucket
    }
    public_access_block {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
  }
}
