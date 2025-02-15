
resource "aws_api_gateway_rest_api" "main" {
  name = var.name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = jsonencode({
    openapi = "3.0.4"
    paths = {
      "/hello" = {
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

resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "res"
}

resource "aws_api_gateway_method" "main" {
  rest_api_id   = aws_api_gateway_resource.main.rest_api_id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id             = aws_api_gateway_method.main.rest_api_id
  resource_id             = aws_api_gateway_method.main.resource_id
  http_method             = aws_api_gateway_method.main.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
  credentials             = aws_iam_role.apigw.arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha256(aws_api_gateway_rest_api.main.body)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name
}

resource "aws_api_gateway_domain_name" "main" {
  domain_name              = var.cf_domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
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
          "IpAddress" : {
            "aws:SourceIp" : concat(
              var.allow_ips,
              # data.aws_ec2_managed_prefix_list.cloudfront.entries[*].cidr
            ),
          }
        }
      },
    ]
  })
}
