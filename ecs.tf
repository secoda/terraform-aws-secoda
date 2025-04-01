# This Terraform configuration file sets up an ECS (Elastic Container Service) cluster
# with Fargate tasks for running containerized applications. It includes setup for
# a multi-container environment with API and frontend services.

locals {
  ecs_batch_secret = var.batch_enabled ? [{ "name" : "INTEGRATION_PARAMS_ENCRYPTION_KEY", "value" : base64encode(random_uuid.batch_encryption_token.result) }] : []

  ecs_batch_vars = var.batch_enabled ? module.integrations.0.ecs_vars : {
    batch_environment_vars = []
    batch_ecs_task_iam_statement = [
      {
        sid       = [""]
        actions   = [""]
        resources = [""]
      }
    ]
    batch_buckets = []
  }
}

################################################################################
# ECS - Cluster
################################################################################

resource "aws_ecs_cluster" "main" {
  name = var.name
}

################################################################################
# Container Service (Fargate)
################################################################################

# Generate a random password for Keycloak database
resource "random_password" "keycloak_database" {
  length  = 16
  special = false
}

# Main ECS module configuration
module "ecs" {
  source = "./ecs/"

  # Basic configuration
  repository_prefix = var.repository_prefix
  cpu_architecture  = var.cpu_architecture
  total_cpu         = var.cpu
  total_memory      = var.memory
  tag               = var.tag
  name              = var.name
  internal          = var.internal

  # Dependencies and integrations
  depends_on = [
    aws_db_instance.postgres, # Must wait for database to spin up to run migrations
  ]

  # Security and access configuration
  ssm_docker = module.secrets-manager.secret_arns["docker-secret-${var.name}-${var.environment}"]

  # Database and cache configurations
  db_addr    = aws_db_instance.postgres.address
  redis_addr = module.redis.endpoint

  # S3 configuration
  private_bucket = module.manifest_bucket.name
  s3_resources = flatten([
    "${module.manifest_bucket.arn}",
    "${module.manifest_bucket.arn}/*",
    local.ecs_batch_vars["batch_buckets"]
  ])

  # Authentication and security configurations
  es_password                = random_password.es.result
  es_host                    = aws_opensearch_domain.es.endpoint
  keycloak_database_password = random_password.keycloak_database.result
  certificate_arn            = var.certificate_arn == "" ? aws_acm_certificate.alb[0].arn : var.certificate_arn

  # AWS specific configurations
  aws_region      = var.aws_region
  associate_alb   = var.associate_alb
  aws_ecs_cluster = aws_ecs_cluster.main
  core_services   = var.core_services
  custom_services = var.custom_services

  # Network configurations
  ecs_vpc_id          = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id
  ecs_private_subnets = var.vpc_id == null ? module.vpc[0].private_subnets : var.private_subnets
  ecs_public_subnets  = var.vpc_id == null ? module.vpc[0].public_subnets : var.public_subnets
  ecs_sg_id           = aws_security_group.ecs_sg.id

  # generated secrets
  api_secret  = random_uuid.api_secret.result
  private_key = base64encode(tls_private_key.jwt.private_key_pem)
  public_key  = base64encode(tls_private_key.jwt.public_key_pem)

  add_environment_vars = flatten([var.add_environment_vars, local.ecs_batch_vars["batch_environment_vars"], local.ecs_batch_secret])

  ecs_task_iam_statement = local.ecs_batch_vars["batch_ecs_task_iam_statement"]
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-${var.name}"
  description = "${var.name} container security group."
  vpc_id      = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id

  tags = {
    Name        = var.name
    Environment = var.environment
    Automation  = "Terraform"
  }
}
