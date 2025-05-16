terraform {
  backend "s3" {
    bucket = "log-monitor-terraform-state"
    key    = "log-monitor/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Rol de ejecución de Lambda
resource "aws_iam_role" "lambda_log_monitor_exec_role" {
  name = "lambda-log-monitor-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Permisos para lectura de S3 (opcional)
resource "aws_iam_policy_attachment" "s3_read_access" {
  name       = "attach-s3-read"
  roles      = [aws_iam_role.lambda_log_monitor_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Política administrada para que Lambda escriba logs en CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_log_monitor_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permisos para acceder a CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "lambda-cloudwatch-logs-access"
  role = aws_iam_role.lambda_log_monitor_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Effect   = "Allow"
        Resource = var.log_group_arn
      }
    ]
  })
}

# Función Lambda
resource "aws_lambda_function" "log_monitor" {
  function_name = "log-monitor"
  role          = aws_iam_role.lambda_log_monitor_exec_role.arn
  handler       = "log-monitor.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/lambda.zip"

  environment {
    variables = {
      SLACK_WEBHOOK_URL  = var.SLACK_WEBHOOK_URL
      LOG_GROUP_NAME     = var.log_group_name
    }
  }

  layers = [
    aws_lambda_layer_version.requests_layer.arn
  ]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# Layer con requests
resource "aws_lambda_layer_version" "requests_layer" {
  filename            = "${path.module}/lambda_layer_requests.zip"
  layer_name          = "requests-layer"
  compatible_runtimes = ["python3.12"]
  source_code_hash    = filebase64sha256("${path.module}/lambda_layer_requests.zip")
}

# Archivar Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${abspath("${path.module}/lambda_source")}"
  output_path = "${abspath("${path.module}/lambda.zip")}"
}

# CloudWatch Metric Filter (detecta 'ERROR' en logs)
resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "log-monitor-error-filter"
  log_group_name = var.log_group_name
  pattern        = "?ERROR ?Error ?error"

  metric_transformation {
    name      = "LogErrorCount"
    namespace = "LogMonitor"
    value     = "1"
  }
}

# Alarm sobre errores detectados
resource "aws_cloudwatch_metric_alarm" "log_error_alarm" {
  alarm_name          = "log-monitor-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "LogErrorCount"
  namespace           = "LogMonitor"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Dispara si se detectan errores en los logs"

  alarm_actions = [aws_lambda_function.log_monitor.arn]
}

# Permitir que CloudWatch Alarms invoque la Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_monitor.function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.log_error_alarm.arn
}

# Permitir que CloudWatch Logs invoque la Lambda (para el trigger real)
resource "aws_lambda_permission" "allow_logs_to_invoke_lambda" {
  statement_id  = "AllowLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_monitor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = var.log_group_arn
}

# Subscription Filter: activa Lambda cuando aparece 'ERROR' en los logs
resource "aws_cloudwatch_log_subscription_filter" "lambda_log_trigger" {
  name            = "log-error-to-lambda"
  log_group_name  = var.log_group_name
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.log_monitor.arn

  depends_on = [
    aws_lambda_permission.allow_logs_to_invoke_lambda
  ]
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/log_monitor"
  retention_in_days = 1
}