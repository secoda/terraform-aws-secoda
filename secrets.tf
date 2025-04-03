module "secrets-manager" {
  source = "./secrets"

  secrets = {
    "docker-secret-${var.name}-${var.environment}" = {
      description = "Secoda docker hub credentials."
      secret_key_value = {
        username = "secodaonpremise"
        password = var.docker_password
        email    = "carter@secoda.co"
      }
    },
  }
}

resource "random_uuid" "batch_encryption_token" {}

resource "tls_private_key" "jwt" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
