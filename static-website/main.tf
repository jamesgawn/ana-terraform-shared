variable "site-name" {
  type = string
}

variable "cert-domain" {
  type = string
}

variable "site-domains" {
  type = list(string)
}

variable "root" {
  type = string
  description = "The default file to return when accessing the root of the domain."
}

variable "github-repo" {
  type = string
}

module "cd" {
  source = "../cloudfront-distribution-via-s3"

  site-name = var.site-name
  cert-domain = var.cert-domain
  site-domains = var.site-domains
  root = var.root
}

resource "aws_iam_role" "codebuild_assume_role" {
  name = "${var.site-name}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.site-name}-codebuild-policy"
  role = aws_iam_role.codebuild_assume_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
       "s3:PutObject",
       "s3:GetObject",
       "s3:GetObjectVersion",
       "s3:GetBucketVersioning",
       "s3:ListBucket",
       "s3:DeleteObject",
       "s3:DeleteObjectVersion"
      ],
      "Resource": ["${module.cd.s3_bucket_arn}","${module.cd.s3_bucket_arn}/*"],
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Resource": [
        "${aws_codebuild_project.build_project.id}"
      ],
      "Action": [
        "codebuild:*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "build_project" {
  name          = "${var.site-name}-build"
  description   = "The CodeBuild project for ${var.site-name}"
  service_role  = aws_iam_role.codebuild_assume_role.arn
  build_timeout = "5"
  badge_enabled = true

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:6.3.1"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "GITHUB"
    location = var.github-repo
    buildspec = "buildspec.yml"
    auth {
      type = "OAUTH"
    }
    report_build_status = true
  }
}

resource "aws_codebuild_webhook" "build_webhook" {
  project_name = aws_codebuild_project.build_project.name
}

output "domain_name" {
  value = module.cd.domain_name
}

output "hosted_zone_id" {
  value = module.cd.hosted_zone_id
}