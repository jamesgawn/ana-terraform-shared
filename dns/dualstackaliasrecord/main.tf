variable "name" {
  type = "string"
}

variable "zone_id" {
  type = "string"
}

variable "alias-target" {
  type = "string"
}

variable "alias-hosted-zone-id" {
  type = "string"
}

resource "aws_route53_record" "a" {
  zone_id = var.zone_id
  name    = var.name
  type    = "A"

  alias {
    evaluate_target_health = false
    name = var.alias-target
    zone_id = var.alias-hosted-zone-id
  }
}

resource "aws_route53_record" "aaaa" {
  zone_id = var.zone_id
  name    = var.name
  type    = "AAAA"

  alias {
    evaluate_target_health = false
    name = var.alias-target
    zone_id = var.alias-hosted-zone-id
  }
}

output "name" {
  value = aws_route53_record.a.name
}

output "zone_id" {
  value = aws_route53_record.a.zone_id
}

