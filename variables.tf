variable "cpu" {
  type    = number
  default = 4096
}

variable "memory" {
  type    = number
  default = 16384
}

variable "rds_max_storage" {
  type    = number
  default = 256
}

variable "rds_allocated_storage" {
  type    = number
  default = 38
}

variable "backup_name" {
  type    = string
  default = null
}

variable "proxy_instance_ami_arch" {
  type    = string
  default = "ARM64"
}

variable "proxy_instance_type" {
  type    = string
  default = "t4g.nano"
}

variable "cpu_architecture" {
  description = "Architecture for fargate instance."
  default     = "X86_64"
  type        = string
}

variable "create_service_linked_role" {
  type    = bool
  default = true
}

variable "es_volume_size" {
  type    = number
  default = 96
}

variable "es_instance_type" {
  type    = string
  default = "t3.medium.search"
}

################################################################################
# Docker Credentials
################################################################################

# Our customer support will provide you with a docker password.
variable "docker_password" {
  type = string
}

################################################################################
# VPC Override
################################################################################

variable "vpc_id" {
  type    = string
  default = null
}
variable "private_subnets" {
  type    = list(string)
  default = null
}

variable "public_subnets" {
  type    = list(string)
  default = null
}

variable "performance_insights_enabled" {
  type    = bool
  default = false
}

variable "database_version" {
  type    = string
  default = "14.15"
}

variable "database_subnets" {
  type    = list(string)
  default = null
}

variable "database_subnet_group_name" {
  type    = string
  default = null
}

variable "aws_availability_zones" {
  type    = list(string)
  default = null
}

################################################################################
# General Networking
################################################################################

# Do not use these values in the code,
# as overriding the vpc (some customers) will make these values incorrect.
variable "cidr" {
  type    = string
  default = "10.9.0.0/16"
}

variable "private_subnets_blocks" {
  type    = list(string)
  default = ["10.9.0.0/24", "10.9.1.0/24"]
}

variable "public_subnets_blocks" {
  type    = list(string)
  default = ["10.9.4.0/24", "10.9.5.0/24"]
}

variable "database_subnets_blocks" {
  type    = list(string)
  default = ["10.9.8.0/24", "10.9.9.0/24"]
}

################################################################################
# Environment
################################################################################

# You may overwrite by setting `environment=` in the `tfvars` file.
variable "environment" {
  type    = string
  default = "on-premise"
}

# You may overwrite by setting `name=` in the `tfvars` file.
variable "name" {
  type    = string
  default = "secoda"
}

# May be modified to suit compliance needs.
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

################################################################################
# Load Balancers
################################################################################

# This may be modified. Note that if it is set to true, you will only be able to access the load balancer from within the AWS VPC subnet network.
variable "internal" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "certificate_arn_2" {
  type    = string
  default = ""
}

################################################################################
# Containers
################################################################################

# Adjust as needed. We suggest Graviton instances (t4g) for better price/performance.
variable "rds_instance_type" {
  type    = string
  default = "db.t4g.small"
}

variable "enable_cidr_ingress" {
  type    = bool
  default = false
}

variable "proxy_instance" {
  type    = bool
  default = false
}

variable "proxy_inbound_cidr" {
  type    = string
  default = ""
}

variable "proxy_public_key" {
  type    = string
  default = ""
}

variable "proxy_port" {
  type    = number
  default = 22
}

variable "proxy_eip" {
  type    = bool
  default = false
}

variable "proxy_private_ip" {
  type    = string
  default = null
}

variable "proxy_user_data" {
  type    = string
  default = null
}

variable "add_environment_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    { name : "AWS_ACCESS_KEY_ID", value : "" },
    { name : "AWS_SECRET_ACCESS_KEY", value : "" },
  ]
}

variable "repository_prefix" {
  type    = string
  default = "secoda/on-premise"
}

variable "tag" {
  default = "2025.1.18"
  type    = string
}

variable "services" {
  type = list(object({
    name      = string
    mem       = number
    cpu       = number
    ports     = list(number)
    essential = bool
    environment = list(object({
      name  = string
      value = string
    }))

    command = list(string)

    dependsOn = list(object({
      containerName = string
      condition     = string
    }))

    healthCheck = object({
      command     = list(string)
      retries     = number
      timeout     = number
      interval    = number
      startPeriod = number
    })

    mountPoints = list(object({
      sourceVolume  = string
      containerPath = string
    }))
  }))

  default = null
}
