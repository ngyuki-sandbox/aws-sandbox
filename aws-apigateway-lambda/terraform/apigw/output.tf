
output "urls" {
  value = [
    "${aws_api_gateway_stage.main.invoke_url}/",
  ]
}

output "invoke_domain" {
  value = "${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.main.name}.amazonaws.com"
}
