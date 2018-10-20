variable "site-name" {
  type = "string"
}

variable "cert-domain" {
  type = "string"
}

// The AWS Cert Manager for globally managed domain names
data "aws_acm_certificate" "cert" {
  provider = "aws.us-east-1"

  domain   = "${var.cert-domain}"
  statuses = ["ISSUED"]
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.site-name}"
}