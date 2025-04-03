################################################################################
# Integration batch queue
################################################################################

module "integrations" {
  count               = var.batch_enabled ? 1 : 0
  source              = "./integrations-batch"
  environment         = "${var.name}-${var.environment}"
  region              = var.aws_region
  vpc_id              = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id
  integration_subnets = var.vpc_id == null ? module.vpc[0].private_subnets : var.private_subnets

  extraction_vcpu  = var.extraction_vcpu
  extraction_image = "${var.repository_prefix}-api:${var.tag}"
  ssm_docker       = module.secrets-manager.secret_arns["docker-secret-${var.name}-${var.environment}"]

  extraction_secrets = []

  extraction_environment_vars = concat([
    {
      "name" : "APISERVICE_DATABASE_CONNECTION",
      "value" : "postgresql://keycloak:${random_password.keycloak_database.result}@${aws_db_instance.postgres.address}:5432/secoda"
    },
    {
      "name" : "ENCRYPTION_KEY",
      "value" : sha256(tls_private_key.jwt.private_key_pem)
    },
    {
      "name" : "PARAMS_ENCRYPTION_KEY",
      "value" : base64encode(random_uuid.batch_encryption_token.result)
    },
    {
      "name" : "PRIVATE_KEY",
      "value" : base64encode(tls_private_key.jwt.private_key_pem)
    },
    {
      "name" : "REDIS_URL",
      "value" : "redis://${module.redis.endpoint}:6379"
    },
    {
      "name" : "PRIVATE_BUCKET",
      "value" : module.manifest_bucket.name,
    },
    {
      "name" : "AWS_ACCOUNT_ID",
      "value" : data.aws_caller_identity.current.account_id,
    },
    {
      "name"  = "PUBLIC_KEY"
      "value" = base64encode(tls_private_key.jwt.public_key_pem)
    },
    {
      "name" : "ES_HOST",
      "value" : aws_opensearch_domain.es.endpoint,
    },
    {
      "name" : "ES_USERNAME",
      "value" : "elastic",
    },
    {
      "name" : "ES_PASSWORD",
      "value" : random_password.es.result,
    }],
    var.add_environment_vars
  )

  extraction_buckets_arn = [
    "${module.manifest_bucket.arn}",
    "${module.manifest_bucket.arn}/*",
  ]
}

