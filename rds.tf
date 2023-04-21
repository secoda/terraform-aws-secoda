locals {
  name = "${var.name}-${var.environment}-postgres"
}

################################################################################
# RDS Module
################################################################################

# The analysis database must be initialized with init_db.sh before it will work with the analysis service

resource "aws_db_instance" "postgres" {
  performance_insights_enabled = var.performance_insights_enabled
  max_allocated_storage      = 60
  allocated_storage          = 12
  engine                     = "postgres"
  engine_version             = var.database_version
  instance_class             = "db.t4g.small" # Adjust as needed. We suggest Graviton instances (t4g) for better price/performance.
  identifier                 = local.name
  name                       = "keycloak"
  username                   = "keycloak"
  password                   = random_password.keycloak_database.result
  skip_final_snapshot        = true
  deletion_protection        = false
  delete_automated_backups   = false
  backup_window              = "10:00-11:00"
  backup_retention_period    = 21
  db_subnet_group_name       = var.database_subnet_group_name != null ? var.database_subnet_group_name : var.name
  vpc_security_group_ids     = concat([aws_security_group.keycloak-security-group.id], var.proxy_instance ? [aws_security_group.cidr_rds_security_group[0].id] : [])
  storage_encrypted          = true
  auto_minor_version_upgrade = false # We recommend you do not upgrade the database version automatically, as it will put the database out-of-sync with the terraform.

  tags = {
    Name        = var.name
    Environment = var.environment
    Automation  = "Terraform"
  }
}

################################################################################
# Security
################################################################################

resource "aws_security_group" "keycloak-security-group" {
  name = "${local.name}-security-group"

  description = "Security group to RDS (terraform) for secoda-${local.name}"
  vpc_id      = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id

  # Only PG in.
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Automation  = "Terraform"
  }
}


resource "aws_security_group" "cidr_rds_security_group" {
  name   = "${local.name}-cidr-rds-security-group"
  count = var.proxy_instance ? 1 : 0
  vpc_id = var.vpc_id == null ? module.vpc[0].vpc_id : var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = [var.cidr]
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Automation  = "Terraform"
  }
}
