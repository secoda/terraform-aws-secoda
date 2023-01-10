module "secrets-manager" {
  source = "./secrets"

  secrets = {
    docker = {
      name = "docker-secret-${var.name}-${var.environment}"
      description = "Secoda docker hub credentials."
      secret_key_value = {
        username = "secodaonpremise"
        password = var.docker_password
        email    = "carter@secoda.co"
      }
    },
  }
}
