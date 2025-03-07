
resource "aws_api_gateway_rest_api" "main" {
  name = var.name

  endpoint_configuration {
    types = ["PRIVATE"]
  }

  body = jsonencode({
    openapi = "3.0.4"
    paths = {
      "/{proxy+}" = {
        get = {
          responses = {
            "200" = {}
          }
          x-amazon-apigateway-integration = {
            type        = "AWS_PROXY"
            uri         = aws_lambda_function.main.invoke_arn
            credentials = aws_iam_role.apigw.arn
            httpMethod  = "POST"
          }
        }
      }
    }
  })
}

resource "terraform_data" "main" {
  input = plantimestamp()

  lifecycle {
    replace_triggered_by = [aws_api_gateway_rest_api_policy.main]
    ignore_changes       = [input]
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha256(join("\n", [
      aws_api_gateway_rest_api.main.body,
      terraform_data.main.output,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_rest_api_policy.main]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name
}

resource "aws_api_gateway_domain_name" "main" {
  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn
  endpoint_configuration {
    types = ["PRIVATE"]
  }
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "execute-api:Invoke",
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = var.vpce_ids
          }
        }
      },
    ]
  })
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id         = aws_api_gateway_rest_api.main.id
  stage_name     = aws_api_gateway_stage.main.stage_name
  domain_name    = aws_api_gateway_domain_name.main.domain_name
  domain_name_id = aws_api_gateway_domain_name.main.domain_name_id
}

resource "aws_iam_role" "apigw" {
  name = "${var.name}-apigw"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "apigw" {
  role_name = aws_iam_role.apigw.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",
  ]
}

resource "aws_api_gateway_rest_api_policy" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "execute-api:Invoke",
        "Effect" : "Allow",
        "Principal" : "*",
        "Resource" : "${aws_api_gateway_rest_api.main.execution_arn}/*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceVpce" : var.vpce_ids
          }
        }
      },
    ]
  })
}
