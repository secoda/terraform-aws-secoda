locals {
  proxy_name = "${var.name}-${var.environment}-proxy"
  stage      = "prd"
  namespace  = "secoda"
}

# Typically used to spin-up a tailscale instance with access to RDS.
module "proxy" {
  count                       = var.proxy_instance ? 1 : 0
  source                      = "cloudposse/ec2-instance/aws"
  version                     = "0.44.0"
  ssh_key_pair                = aws_key_pair.proxy[0].key_name
  vpc_id                      = module.vpc[0].vpc_id
  subnet                      = module.vpc[0].public_subnets[0]
  associate_public_ip_address = true
  name                        = local.proxy_name
  namespace                   = local.namespace
  stage                       = local.stage

  security_group_rules = [
    {
      type        = "egress"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    # Allow inbound from the local VPC to the bastion.
    {
      type        = "ingress"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [var.vpc_id == null ? module.vpc[0].vpc_cidr_block : data.aws_vpc.override[0].cidr_block]
    },
    # Allow limited public access to the bastion.
    {
      type        = "ingress"
      from_port   = var.proxy_port
      to_port     = var.proxy_port
      protocol    = "tcp"
      cidr_blocks = [var.proxy_inbound_cidr]
    }
  ]
}

resource "aws_key_pair" "proxy" {
  count      = var.proxy_instance ? 1 : 0
  key_name   = local.proxy_name
  public_key = var.proxy_public_key
}

