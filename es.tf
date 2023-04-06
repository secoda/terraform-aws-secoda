locals {
  domain   = "es-${var.name}"
  username = "secoda"
}

data "aws_caller_identity" "current" {}

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

resource "aws_elasticsearch_domain" "es" {
  domain_name           = local.domain
  elasticsearch_version = "7.10"

  ebs_options {
    ebs_enabled = true
    volume_size = 32
    volume_type = "gp3"
    throughput  = 125
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
      master_user_name     = local.username
      master_user_password = random_password.es.result
    }
  }

  cluster_config {
    instance_type = "t4g.small.elasticsearch"
  }

  encrypt_at_rest {
    enabled = true
  }

  vpc_options {
    subnet_ids         = [module.vpc.private_subnets[0]]
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
            "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${local.domain}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain      = local.domain
    Environment = var.name
    Terraform   = "true"
  }
}

resource "aws_security_group" "es" {
  name        = "es-${local.domain}"
  description = "Managed by Terraform"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = module.vpc.private_subnets

}

# This may be required for ES on new accounts.

# resource "aws_iam_service_linked_role" "es" {
#   aws_service_name = "es.amazonaws.com"
# }
