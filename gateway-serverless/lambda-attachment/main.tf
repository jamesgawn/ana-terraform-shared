variable "route" {
  type = string
  description = "The route you wish to attach the function to. e.g. $default or GET /blah"
}

variable "lambda_name" {
  type = string
  description = "The name of the lambda"
}

variable "api_gateway_id" {
  type = string
}

data "aws_lambda_function" "function" {
  function_name = var.lambda_name
}

data "aws_apigatewayv2_api" "gateway" {
  api_id = var.api_gateway_id
}

resource "aws_lambda_permission" "function" {
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_apigatewayv2_api.gateway.arn}/*/*/*"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id                  = var.api_gateway_id
  integration_type        = "AWS_PROXY"
  integration_uri         = data.aws_lambda_function.function.arn
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = var.api_gateway_id
  route_key = var.route
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}