locals {
  proxy_name = "${var.name}-${var.environment}-proxy"
  stage      = "prd"
  namespace  = "secoda"
}


data "aws_ami" "arm64" {
  most_recent = true
  filter {
    name   = "creation-date"
    values = ["2023-10-31*"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/*23.04-arm64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical owner ID for Ubuntu AMIs
}


data "aws_ami" "amd64" {
  most_recent = true
  filter {
    name   = "creation-date"
    values = ["2023-10-31*"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/*23.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical owner ID for Ubuntu AMIs
}

# Typically used to spin-up a tailscale instance with access to RDS.
module "proxy" {
  count                       = var.proxy_instance ? 1 : 0
  source                      = "cloudposse/ec2-instance/aws"
  version                     = ">= 1.1.0, < 2.0.0"
  ssh_key_pair                = aws_key_pair.proxy[0].key_name
  vpc_id                      = module.vpc[0].vpc_id
  subnet                      = module.vpc[0].public_subnets[0]
  ami                         = var.proxy_instance_ami_arch == "ARM64" ? data.aws_ami.arm64.id : data.aws_ami.amd64.id
  instance_type               = var.proxy_instance_type
  assign_eip_address          = var.proxy_eip
  private_ip                  = var.proxy_private_ip
  name                        = local.proxy_name
  namespace                   = local.namespace
  stage                       = local.stage
  associate_public_ip_address = true

  user_data = var.proxy_user_data

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

