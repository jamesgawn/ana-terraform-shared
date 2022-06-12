variable "name" {
  type = string
  description = "The name of the API gateway."
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.name}"
  protocol_type = "HTTP"
  disable_execute_api_endpoint = true
}

resource "aws_cloudwatch_log_group" "api" {
  name = "${var.name}"
  retention_in_days = 14
}

resource "aws_apigatewayv2_stage" "api" {
  api_id = aws_apigatewayv2_api.api.id
  name   = "prod"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = <<EOF
    { "requestId":"$context.requestId", "ip": "$context.identity.sourceIp", "requestTime":"$context.requestTime", "httpMethod":"$context.httpMethod","routeKey":"$context.routeKey", "status":"$context.status","protocol":"$context.protocol", "responseLength":$context.responseLength, "integrationStatus": $context.integrationStatus, "integrationErrorMessage": "$context.integrationErrorMessage", "integration": { "error": "$context.integration.error", "integrationstatus": $context.integration.integrationStatus, "latency": $context.integration.latency, "requestId": "$context.integration.requestId", "status": $context.integration.status } }
EOF
  }
}
