locals {
  services = tolist([
    {
      tag       = "7.4.6"
      name        = "api"
      mem         = floor(3 * var.memory / 4)
      cpu         = floor(3 * var.cpu / 4)
      ports       = [5007]
      essential   = true
      image       = false
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
      ulimits     = null
    },
    {
      tag       = "7.4.6"
      name        = "frontend"
      mem         = floor(1 * var.memory / 4)
      cpu         = floor(1 * var.cpu / 4)
      ports       = [443]
      essential   = true
      image       = false
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
      ulimits     = null
    }
  ])
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

resource "random_password" "keycloak_database" {
  length  = 16
  special = false
}

module "ecs" {
  source = "./ecs/"

  cpu_architecture = var.cpu_architecture

  cpu    = var.cpu
  memory = var.memory

  depends_on = [
    aws_db_instance.postgres, # Must wait for database to spin up to run migrations.
  ]

  name     = var.name
  internal = var.internal # Whether this instance should have a load balancer that resolves to a private ip address.

  ssm_docker = module.secrets-manager.secret_arns["docker-secret-${var.name}-${var.environment}"]

  db_addr    = aws_db_instance.postgres.address # Used for keycloak and analytics.
  redis_addr = module.redis.endpoint            # Used for the job queue.

  private_bucket = module.manifest_bucket.name

  s3_resources = [
    "${module.manifest_bucket.arn}",
    "${module.manifest_bucket.arn}/*"
  ] # Optional, the s3 buckets this task should have access to. In policy statement resource format. Typically used for accessing the S3 bucket of manifest files.

  es_password                = random_password.es.result
  es_host                    = aws_opensearch_domain.es.endpoint
  keycloak_database_password = random_password.keycloak_database.result

  # Set the certificate if it is supplied, otherwise use the self-signed one.
  certificate_arn = var.certificate_arn == "" ? aws_acm_certificate.alb[0].arn : var.certificate_arn

  aws_region           = var.aws_region
  associate_alb        = true
  aws_ecs_cluster      = aws_ecs_cluster.main
  add_environment_vars = var.add_environment_vars
  services             = local.services

  ecs_vpc_id          = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id
  ecs_private_subnets = var.vpc_id == null ? module.vpc[0].private_subnets : var.private_subnets
  ecs_public_subnets  = var.vpc_id == null ? module.vpc[0].public_subnets : var.public_subnets

  ecs_sg_id = aws_security_group.ecs_sg.id
}

# Need to pull this out so that we can reference it in the RDS, etc.
# Because ecs depends_on RDS, this must be created first.
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
