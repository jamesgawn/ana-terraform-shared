variable "site-name" {
  type = "string"
  default = "website-gawn-subdomain"
}

variable "cert-domain" {
  type = "string"
}

variable "github_username" {
  type    = "string"
  default = "jamesgawn"
}

variable "github_token" {
  type = "string"
}

variable "github_repo" {
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