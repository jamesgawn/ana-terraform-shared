variable "cert_domain" {
  type = string
  description = "The primary domain name on the cert within certificate manager. e.g. gawn.uk"
}

variable "domain" {
  type = string
  description = "The domain you wish to attach to the gateway. e.g. api.gawn.uk"
}

variable "gateway-id" {
  type = string
  description = "The ID for the gateway to attach to"
}

variable "gateway-stage-id" {
  type = string
  description = "The ID for the gateway stage to attach to"
}

data "aws_acm_certificate" "api_cert" {
  domain   = var.cert_domain
  statuses = ["ISSUED"]
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = var.domain

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.api_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "example" {
  api_id      = var.gateway-id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = var.gateway-stage-id
}

data "aws_route53_zone" "api" {
  name = var.zone
  private_zone = false
}

resource "aws_route53_record" "api" {
  name    = aws_apigatewayv2_domain_name.api.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.api.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}