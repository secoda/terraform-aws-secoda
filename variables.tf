################################################################################
# Compute Resources
################################################################################
variable "cpu" {
  description = "Total CPU units to allocate for the ECS task (1024 units = 1 vCPU)"
  type        = number
  default     = 4096
}

variable "memory" {
  description = "Total memory (in MiB) to allocate for the ECS task"
  type        = number
  default     = 16384
}

variable "cpu_architecture" {
  description = "Architecture for fargate instance."
  default     = "X86_64"
  type        = string
}

################################################################################
# Database Configuration
################################################################################
variable "rds_max_storage" {
  description = "Maximum storage limit (in GB) for RDS auto-scaling"
  type        = number
  default     = 256
}

variable "rds_allocated_storage" {
  description = "Initial storage allocation (in GB) for RDS instance"
  type        = number
  default     = 38
}

variable "rds_instance_type" {
  type    = string
  default = "db.t4g.small"
}

variable "database_version" {
  type    = string
  default = "14.15"
}

variable "performance_insights_enabled" {
  type    = bool
  default = false
}

################################################################################
# Elasticsearch Configuration
################################################################################
variable "es_volume_size" {
  type    = number
  default = 96
}

variable "es_instance_type" {
  type    = string
  default = "t3.medium.search"
}

################################################################################
# Proxy Configuration
################################################################################
variable "proxy_instance" {
  type    = bool
  default = false
}

variable "proxy_instance_ami_arch" {
  type    = string
  default = "ARM64"
}

variable "proxy_instance_type" {
  type    = string
  default = "t4g.nano"
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

################################################################################
# Networking Configuration
################################################################################
variable "vpc_id" {
  description = "ID of an existing VPC to use instead of creating a new one"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "List of existing private subnet IDs to use instead of creating new ones"
  type        = list(string)
  default     = null
}

variable "public_subnets" {
  description = "List of existing public subnet IDs to use instead of creating new ones"
  type        = list(string)
  default     = null
}

variable "database_subnets" {
  type    = list(string)
  default = null
}

variable "database_subnet_group_name" {
  type    = string
  default = null
}

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

variable "aws_availability_zones" {
  type    = list(string)
  default = null
}

################################################################################
# Load Balancer Configuration
################################################################################
variable "internal" {
  type    = bool
  default = false
}

variable "associate_alb" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "certificate_arn_2" {
  type    = string
  default = ""
}

variable "enable_cidr_ingress" {
  type    = bool
  default = false
}

################################################################################
# Environment & Tagging
################################################################################
variable "environment" {
  description = "Environment name for resource tagging and identification"
  type        = string
  default     = "on-premise"
}

variable "name" {
  description = "Name prefix for all resources created by this module"
  type        = string
  default     = "secoda"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

################################################################################
# Container & Service Configuration
################################################################################
variable "docker_password" {
  description = "Docker registry password provided by customer support for accessing container images"
  type        = string
}

variable "repository_prefix" {
  type    = string
  default = "secoda/on-premise"
}

variable "tag" {
  default = "2025.2.1"
  type    = string
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

variable "core_services" {
  description = "Configuration for core services (API and Frontend) running in ECS tasks. Defines resource allocation, health checks, and dependencies"
  type = list(object({
    name                        = string
    preferred_memory_percentage = number
    preferred_cpu_percentage    = number
    ports                       = list(number)
    essential                   = bool
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
  default = [
    {
      name                        = "api"
      preferred_memory_percentage = 75
      preferred_cpu_percentage    = 75
      ports                       = [5007]
      essential                   = true
      environment                 = []
      command                     = null
      dependsOn                   = []
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
      name                        = "frontend"
      preferred_memory_percentage = 25
      preferred_cpu_percentage    = 25
      ports                       = [443]
      essential                   = true
      environment                 = []
      command                     = null
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
  ]
}

variable "custom_services" {
  type = list(object({
    name              = string
    image             = string
    cpu               = optional(number)
    memoryReservation = optional(number)
    essential         = optional(bool)
    entryPoint        = optional(list(string))
    command           = optional(list(string))
    workingDirectory  = optional(string)
    environment = optional(list(object({
      name  = string
      value = string
    })))
    environmentFiles = optional(list(object({
      value = string
      type  = string
    })))
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })))
    mountPoints = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = optional(bool)
    })))
    volumesFrom = optional(list(object({
      sourceContainer = string
      readOnly        = optional(bool)
    })))
    portMappings = optional(list(object({
      containerPort = number
      hostPort      = optional(number)
      protocol      = optional(string)
    })))
    healthCheck = optional(object({
      command     = list(string)
      interval    = optional(number)
      timeout     = optional(number)
      retries     = optional(number)
      startPeriod = optional(number)
    }))
    logConfiguration = optional(object({
      logDriver = string
      options   = map(string)
    }))
  }))
  default = null
}

################################################################################
# Miscellaneous
################################################################################
variable "backup_name" {
  type        = string
  default     = null
  description = "Name of the backup"
}

variable "create_service_linked_role" {
  type        = bool
  default     = true
  description = "Create a service linked role for OpenSearch"
}

################################################################################
# Batch
################################################################################
variable "batch_enabled" {
  type    = bool
  default = false
}

variable "extraction_vcpu" {
  type    = number
  default = 32
}

