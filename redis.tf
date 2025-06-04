module "this" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = "secoda-redis"
  stage     = "production"
  name      = var.name
}

module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "~> 1.0, < 1.3.0"

  parameter = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    }
  ]

  replication_group_id = "${var.name}-rg-queue"

  availability_zones = var.aws_availability_zones != null ? var.aws_availability_zones : [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  vpc_id             = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id

  allowed_security_group_ids = [aws_security_group.ecs_sg.id]
  additional_security_group_rules = [
    {
      type        = "ingress"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [var.vpc_id == null ? module.vpc[0].vpc_cidr_block : data.aws_vpc.override[0].cidr_block]
    }
  ]
  subnets                    = var.vpc_id == null ? module.vpc[0].database_subnets : var.database_subnets
  cluster_size               = 1
  instance_type              = "cache.t4g.medium"
  apply_immediately          = true
  automatic_failover_enabled = false
  engine_version             = "6.x"
  family                     = "redis6.x"
  at_rest_encryption_enabled = true
  # Due to limitations with celery, we need to disable in transit encryption.
  # This carries very minimal security risk as the redis cluster is only accessible from the VPC.
  transit_encryption_enabled = false
  context                    = module.this.context
}

