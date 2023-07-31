data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# These special characters are used, since they can cause
# issues with the ES API.
resource "random_password" "es" {
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "_"
}

resource "aws_opensearch_domain" "es" {
  domain_name    = var.name
  engine_version = "OpenSearch_2.5"

  ebs_options {
    ebs_enabled = true
    volume_size = var.es_volume_size
    volume_type = "gp3"
    throughput  = 256
    iops        = 3000
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = "elastic"
      master_user_password = random_password.es.result
    }
  }

  cluster_config {
    instance_type = var.es_instance_type
  }

  encrypt_at_rest {
    enabled = true
  }

  vpc_options {
    subnet_ids         = [var.vpc_id == null ? module.vpc[0].private_subnets[0] : var.private_subnets[0]]
    security_group_ids = [aws_security_group.es.id]
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.name}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain      = var.name
    Environment = var.environment
    Terraform   = "true"
  }

  depends_on = [
    aws_iam_service_linked_role.os,
  ]
}

resource "aws_security_group" "es" {
  name        = "es-${var.name}"
  description = "Managed by Terraform"
  vpc_id      = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [var.vpc_id == null ? module.vpc[0].vpc_cidr_block : data.aws_vpc.override[0].cidr_block]
  }
}

# This may be required for OpenSearch on new AWS accounts.
resource "aws_iam_service_linked_role" "os" {
  count            = var.create_service_linked_role == true ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
}
