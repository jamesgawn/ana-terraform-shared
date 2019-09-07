variable "name" {
  type = "string"
}

variable "zone_id" {
  type = "string"
}

resource "aws_route53_zone" "child-zone" {
  name = var.name
}

resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name    = var.name
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.child-zone.name_servers
}