################################################################################
# Resource Allocation
################################################################################

variable "total_cpu" {
  description = "Total CPU units to allocate for the ECS task (1024 units = 1 vCPU)"
  type        = number
  default     = 4096
}

variable "total_memory" {
  description = "Total memory (in MiB) to allocate for the ECS task"
  type        = number
  default     = 8192
}

################################################################################
# Database and Cache Configuration
################################################################################

variable "redis_addr" {
  description = "Redis connection address"
  type        = string
}

variable "db_addr" {
  description = "Database connection address"
  type        = string
}

variable "keycloak_database_password" {
  description = "The password for the Keycloak database"
  type        = string
}

variable "es_host" {
  description = "Elasticsearch host address"
  type        = string
  default     = null
}

variable "es_password" {
  description = "Elasticsearch password"
  type        = string
  default     = null
}

################################################################################
# Storage Configuration
################################################################################

variable "s3_resources" {
  description = "List of S3 resource ARNs for private bucket access"
  type        = list(string)
}

variable "private_bucket" {
  description = "Name of the private S3 bucket where application files will be stored"
  type        = string
}

################################################################################
# Container Registry Configuration
################################################################################

variable "ssm_docker" {
  description = "SSM parameter name containing Docker Hub authentication credentials"
  type        = string
}

variable "repository_prefix" {
  description = "Prefix for container image repository path"
  type        = string
  default     = "secoda/on-premise"
}

variable "ecr_repo_arns" {
  description = "List of ECR repository ARNs to grant access to. Default allows all repositories"
  type        = list(string)
  default     = ["*"]
}

################################################################################
# ECS Cluster Configuration
################################################################################

variable "name" {
  description = "The service name"
  type        = string
}

variable "cpu_architecture" {
  description = "CPU architecture for Fargate instance (X86_64 or ARM64)"
  type        = string
  default     = "X86_64"
}

variable "ecs_sg_id" {
  description = "Security group ID for the ECS service"
  type        = string
}

variable "aws_ecs_cluster" {
  description = "ECS cluster configuration object"
  type = object({
    name = string
    arn  = string
  })
}

variable "custom_services" {
  type = list(object({
    name             = string
    image            = string
    cpu              = optional(number)
    memory           = optional(number)
    essential        = optional(bool)
    entryPoint       = optional(list(string))
    command          = optional(list(string))
    workingDirectory = optional(string)
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
  default     = null
  description = "List of custom container definitions that conform to AWS ECS container definition schema"
}

variable "add_environment_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tag" {
  type = string
}

variable "core_services" {
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
}

################################################################################
# Network Configuration
################################################################################

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "ecs_vpc_id" {
  description = "VPC ID where ECS resources will be deployed"
  type        = string
}

variable "ecs_private_subnets" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_public_subnets" {
  description = "List of public subnet IDs for ECS tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether instances should be accessible from the public internet"
  type        = bool
  default     = false
}

variable "internal" {
  description = "Whether the load balancer should be internal (private IP)"
  type        = bool
  default     = false
}

################################################################################
# Load Balancer Configuration
################################################################################

variable "health_check_url" {
  description = "URL path for health check endpoint"
  type        = string
  default     = "/healthcheck/"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Whether to enable HTTPS for the service"
  type        = bool
  default     = true
}

variable "cloudwatch_alarm_name" {
  description = "Base name for CPU and Memory CloudWatch alarms"
  type        = string
  default     = ""
}

variable "cloudwatch_alarm_actions" {
  description = "The list of actions to take for cloudwatch alarms"
  type        = list(string)
  default     = []
}

variable "cloudwatch_alarm_cpu_enable" {
  description = "Enable the CPU Utilization CloudWatch metric alarm"
  default     = true
  type        = bool
}

variable "cloudwatch_alarm_cpu_threshold" {
  description = "The CPU Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = number
}

variable "cloudwatch_alarm_mem_enable" {
  description = "Enable the Memory Utilization CloudWatch metric alarm"
  default     = true
  type        = bool
}

variable "cloudwatch_alarm_mem_threshold" {
  description = "The Memory Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = number
}

variable "logs_cloudwatch_retention" {
  description = "Number of days you want to retain log events in the log group."
  default     = 365
  type        = number
}

variable "logs_cloudwatch_group" {
  description = "CloudWatch log group to create and use. Default: /ecs/{name}-{environment}"
  default     = ""
  type        = string
}

variable "ecs_use_fargate" {
  description = "Whether to use Fargate for the task definition."
  default     = false
  type        = bool
}

variable "ecs_instance_role" {
  description = "The name of the ECS instance role."
  default     = ""
  type        = string
}

variable "ec2_create_task_execution_role" {
  description = "Set to true to create ecs task execution role to ECS EC2 Tasks."
  type        = bool
  default     = true
}

variable "fargate_platform_version" {
  description = "Fargate platform version for running the service"
  type        = string
  default     = "LATEST"
}

variable "fargate_task_cpu" {
  description = "Number of cpu units used in initial task definition. Default is minimum."
  type        = number
  default     = 4096
}

variable "fargate_task_memory" {
  description = "Amount (in MiB) of memory used in initial task definition. Default is minimum."
  type        = number
  default     = 16384
}

variable "tasks_desired_count" {
  description = "Desired number of running task instances"
  type        = number
  default     = 1
}

variable "tasks_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks."
  default     = 100
  type        = number
}

variable "tasks_maximum_percent" {
  description = "Upper limit on the number of running tasks."
  default     = 200
  type        = number
}

variable "container_definitions" {
  description = "Container definitions provided as valid JSON document. Default uses golang:alpine running a simple hello world."
  default     = ""
  type        = string
}

variable "target_container_name" {
  description = "Name of the container the Load Balancer should target. Default: {name}-{environment}"
  default     = "frontend"
  type        = string
}

variable "associate_alb" {
  description = "Whether to associate an Application Load Balancer (ALB) with the ECS service."
  default     = false
  type        = bool
}

variable "associate_nlb" {
  description = "Whether to associate a Network Load Balancer (NLB) with the ECS service."
  default     = false
  type        = bool
}

variable "alb_security_group" {
  description = "Application Load Balancer (ALB) security group ID to allow traffic from."
  default     = ""
  type        = string
}

variable "nlb_subnet_cidr_blocks" {
  description = "List of Network Load Balancer (NLB) CIDR blocks to allow traffic from."
  default     = []
  type        = list(string)
}

variable "additional_security_group_ids" {
  description = "In addition to the security group created for the service, a list of security groups the ECS service should also be added to."
  default     = []
  type        = list(string)
}

variable "lb_target_groups" {
  description = "List of load balancer target group objects containing the lb_target_group_arn, container_port and container_health_check_port. The container_port is the port on which the container will receive traffic. The container_health_check_port is an additional port on which the container can receive a health check. The lb_target_group_arn is either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with."
  default     = []
  type = list(
    object({
      container_port              = number
      container_health_check_port = number
      lb_target_group_arn         = string
      }
    )
  )
}

variable "container_port" {
  default     = 443
  description = "Port for the container app to listen on. The app currently supports listening on two ports."
  type        = number
}

variable "service_registries" {
  description = "List of service registry objects as per <https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1>. List can only have a single object until <https://github.com/terraform-providers/terraform-provider-aws/issues/9573> is resolved."
  type = list(object({
    registry_arn   = string
    container_name = string
  }))
  default = []
}

variable "health_check_grace_period_seconds" {
  description = "Grace period within which failed health checks will be ignored at container start. Only applies to services with an attached loadbalancer."
  default     = 30
  type        = number
}