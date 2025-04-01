
resource "aws_cloudwatch_log_group" "integration" {
  name              = local.awslogs_group
  retention_in_days = var.logs_cloudwatch_retention

  kms_key_id = aws_kms_key.integration.arn
}

resource "aws_cloudwatch_log_group" "integration_batch_log_group" {
  name              = "int_batch_${var.environment}"
  retention_in_days = var.logs_cloudwatch_retention
}

resource "aws_cloudwatch_log_group" "extraction" {
  name              = local.awslogs_group_ext
  retention_in_days = var.logs_cloudwatch_retention

  kms_key_id = aws_kms_key.integration.arn
}

resource "aws_cloudwatch_log_group" "extraction_batch_log_group" {
  name              = "ext_batch_${var.environment}"
  retention_in_days = var.logs_cloudwatch_retention
}

