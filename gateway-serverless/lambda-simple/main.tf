variable "name" {
  type = string
}

variable "description" {
  type = string
  default = ""
}

variable "handler" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "memory_size" {
  type = number
  default = 128
}

variable "timeout" {
  type = number
  default = 3
}

variable "runtime" {
  type = string
}

data "archive_file" "lambda_code" {
  type        = "zip"
  output_path = "${path.root}/deploy/${var.name}.zip"
  source_dir = var.source_dir
}

resource "aws_lambda_function" "lambda" {
  function_name = var.name
  description = var.description

  handler = var.handler
  runtime = var.runtime
  filename = data.archive_file.lambda_code.output_path
  source_code_hash = data.archive_file.lambda_code.output_sha
  memory_size = var.memory_size
  timeout = var.timeout

  role = aws_iam_role.lambda_execution_role.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.name}-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution_basis_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda_execution_role.name
}

data "aws_sns_topic" "notification_alerts" {
  name = var.notification_sns_queue_name
}

output "lambda_execution_role_name" {
  value = aws_iam_role.lambda_execution_role.name
}

output "lambda_function_arn" {
  value = aws_lambda_function.lambda.arn
}

output "name" {
  value = aws_lambda_function.lambda.function_name
}