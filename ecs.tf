# This Terraform configuration file sets up an ECS (Elastic Container Service) cluster
# with Fargate tasks for running containerized applications. It includes setup for
# a multi-container environment with API and frontend services.

################################################################################
# Local Variables
################################################################################

locals {
  # Default service definitions for the ECS tasks
  # Configures two services:
  # 1. API service (75% of resources)
  # 2. Frontend service (25% of resources)
  services = coalesce(var.services, tolist([
    {
      name        = "api"
      mem         = floor(3 * var.memory / 4)  # Allocates 75% of total memory
      cpu         = floor(3 * var.cpu / 4)     # Allocates 75% of total CPU
      ports       = [5007]
      essential   = true
      environment = []
      command     = null
      dependsOn   = []
      healthCheck = {
        "retries" : 3,
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:5007/healthcheck/ || exit 1"
        ],
        "timeout" : 5,
        "interval" : 5,
        "startPeriod" : 60
      }
      mountPoints = null
    },
    {
      name        = "frontend"
      mem         = floor(1 * var.memory / 4)  # Allocates 25% of total memory
      cpu         = floor(1 * var.cpu / 4)     # Allocates 25% of total CPU
      ports       = [443]
      essential   = true
      environment = []
      command     = null
      dependsOn = [
        {
          "containerName" = "api"
          "condition"     = "HEALTHY"
        }
      ]
      healthCheck = {
        "retries" : 3,
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:5006/healthcheck/ || exit 1"
        ],
        "timeout" : 5,
        "interval" : 5,
        "startPeriod" : 60
      }
      mountPoints = null
    }
  ]))
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
  cpu              = var.cpu
  memory           = var.memory
  tag              = var.tag
  name             = var.name
  internal         = var.internal

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
  s3_resources = [
    "${module.manifest_bucket.arn}",
    "${module.manifest_bucket.arn}/*"
  ]

  # Authentication and security configurations
  es_password                = random_password.es.result
  es_host                    = aws_opensearch_domain.es.endpoint
  keycloak_database_password = random_password.keycloak_database.result
  certificate_arn           = var.certificate_arn == "" ? aws_acm_certificate.alb[0].arn : var.certificate_arn

  # AWS specific configurations
  aws_region      = var.aws_region
  associate_alb   = true
  aws_ecs_cluster = aws_ecs_cluster.main
  services        = local.services

  # Network configurations
  ecs_vpc_id          = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id
  ecs_private_subnets = var.vpc_id == null ? module.vpc[0].private_subnets : var.private_subnets
  ecs_public_subnets  = var.vpc_id == null ? module.vpc[0].public_subnets : var.public_subnets
  ecs_sg_id          = aws_security_group.ecs_sg.id

  add_environment_vars = var.add_environment_vars
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
