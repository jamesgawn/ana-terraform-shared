variable "site-name" {
  type = "string"
}

variable "cert-domain" {
  type = "string"
}

variable "site-domains" {
  type = "list"
}

variable "root" {
  type = "string"
  description = "The default file to return when accessing the root of the domain."
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

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Identity for ${var.site-name}"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "access_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.bucket.bucket_domain_name}"
    origin_id   = "${var.site-name}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "${var.root}"


  aliases = "${var.site-domains}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.site-name}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    "geo_restriction" {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${data.aws_acm_certificate.cert.arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"`
  }
}
