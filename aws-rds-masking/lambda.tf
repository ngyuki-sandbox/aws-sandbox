
resource "terraform_data" "layer" {
  input            = "layer.zip"
  triggers_replace = filebase64sha256("${path.module}/lambda/package-lock.json")
  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p .layer &&\
      rm -fr .layer/* &&\
      cp package.json package-lock.json .layer/ &&\
      env --chdir=.layer/ npm ci --omit=dev
    EOT
    working_dir = "${path.module}/lambda"
  }
}

data "archive_file" "layer" {
  type             = "zip"
  source_dir       = "${path.module}/lambda/.layer/"
  output_path      = "${path.module}/lambda/${terraform_data.layer.output}"
  output_file_mode = "0644"
}

resource "aws_lambda_layer_version" "layer" {
  filename                 = data.archive_file.layer.output_path
  layer_name               = "rds-masking"
  compatible_architectures = ["x86_64"]
  compatible_runtimes      = ["nodejs18.x"]
}

data "archive_file" "lambda" {
  type             = "zip"
  source_file      = "${path.module}/lambda/index.mjs"
  output_path      = "${path.module}/lambda/lambda.zip"
  output_file_mode = "0644"
}

resource "aws_iam_role" "lambda" {
  name = "rds-masking-lambda"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
}

resource "aws_lambda_function" "lambda" {
  function_name    = "rds-masking"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 900
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [aws_lambda_layer_version.layer.arn]
  vpc_config {
    subnet_ids         = data.aws_db_subnet_group.main.subnet_ids
    security_group_ids = var.lambda_security_group_ids
  }
}

resource "aws_lambda_invocation" "lambda" {
  for_each      = { for sql in var.sqls : sha1(sql) => sql }
  function_name = aws_lambda_function.lambda.function_name
  input = jsonencode({
    MYSQL_HOST : aws_rds_cluster.main.endpoint,
    MYSQL_USER : var.rds_username,
    MYSQL_PASSWORD : var.rds_password,
    MYSQL_DATABASE : var.rds_database,
    MYSQL_SQL : each.value
  })
  depends_on = [aws_rds_cluster_instance.main]
}
