
resource "aws_api_gateway_rest_api" "api" {
  name = var.name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = jsonencode({
    openapi = "3.0.1"
    paths = {
      "/stream" = {
        post = {
          responses = {
            "200" = {}
          }
          x-amazon-apigateway-integration = {
            type                = "AWS"
            connectionType      = "INTERNET"
            httpMethod          = "POST"
            uri                 = "arn:aws:apigateway:${data.aws_region.main.name}:kinesis:action/PutRecord"
            credentials         = aws_iam_role.api.arn
            passthroughBehavior = "NEVER"

            requestTemplates = {
              "application/json" = jsonencode({
                StreamName   = aws_kinesis_stream.stream.name
                Data         = "$util.base64Encode($input.json('$.Data'))"
                PartitionKey = "$input.path('$.PartitionKey')"
              })
            }

            responses = {
              "2\\d\\d" : {
                "statusCode" : "200",
                "responseTemplates" : {
                  "application/json" : jsonencode({
                    "sequence" : "$input.path('$.SequenceNumber')",
                    "shard" : "$input.path('$.ShardId')",
                  })
                }
              }
            }
          }
        }
      }
    }
  })
}

# resource "aws_api_gateway_resource" "api" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   path_part   = "stream"
# }

# resource "aws_api_gateway_method" "api" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.api.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "api" {
#   rest_api_id             = aws_api_gateway_rest_api.api.id
#   resource_id             = aws_api_gateway_resource.api.id
#   http_method             = aws_api_gateway_method.api.http_method
#   type                    = "AWS"
#   connection_type         = "INTERNET"
#   credentials             = aws_iam_role.api.arn
#   integration_http_method = "POST"
#   uri                     = "arn:aws:apigateway:${data.aws_region.main.name}:kinesis:action/PutRecord"
#   passthrough_behavior    = "NEVER"

#   request_templates = {
#     "application/json" = jsonencode({
#       StreamName   = aws_kinesis_stream.stream.name
#       Data         = "$util.base64Encode($input.json('$.Data'))"
#       PartitionKey = "$input.path('$.PartitionKey')"
#     })
#   }
# }

# resource "aws_api_gateway_method_response" "api" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.api.id
#   http_method = aws_api_gateway_method.api.http_method
#   status_code = "200"
# }

# resource "aws_api_gateway_integration_response" "api" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.api.id
#   http_method = aws_api_gateway_method.api.http_method
#   status_code = aws_api_gateway_method_response.api.status_code
# }

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(aws_api_gateway_rest_api.api.body)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}


resource "aws_iam_role" "api" {
  name = "${var.name}-api"
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

resource "aws_iam_role_policy" "api" {
  role = aws_iam_role.api.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kinesis:PutRecord",
        ],
        "Resource" : aws_kinesis_stream.stream.arn,
      },
    ]
  })
}
