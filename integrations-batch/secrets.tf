resource "random_uuid" "encryption_token" {}

resource "aws_secretsmanager_secret" "encryption_token" {
  name = "${var.environment}/int_batch_params_encryption_token/master"
}

resource "aws_secretsmanager_secret_version" "encryption_token" {
  secret_id     = aws_secretsmanager_secret.encryption_token.id
  secret_string = base64encode(random_uuid.encryption_token.result)
}

