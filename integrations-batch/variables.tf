variable "name" {
  type    = string
  default = "int-batch"
}

variable "name_ext" {
  type    = string
  default = "ext-batch"
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "integration_subnets" {
  type = list(string)
}

variable "extraction_vcpu" {
  description = "extraction compute environment max cpu allocation"
  default     = 32
  type        = number
}

variable "integration_vcpu" {
  description = "integration compute environment max cpu allocation"
  default     = 32
  type        = number
}

variable "cpu_architecture" {
  description = "Architecture for fargate instance."
  default     = "ARM64"
  type        = string
}

variable "logs_cloudwatch_retention" {
  description = "Number of days you want to retain log events in the log group."
  default     = 365
  type        = number
}

variable "cloudwatch_alarm_cpu_threshold" {
  description = "The CPU Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = number
}

variable "cloudwatch_alarm_mem_threshold" {
  description = "The Memory Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = number
}

variable "cloudwatch_alarm_sqs_age_threshold" {
  description = "The maximum age threshold for the CloudWatch metric alarm"
  default     = 21600
  type        = number
}

variable "cloudwatch_alarm_actions" {
  description = "actions to take on alarm state"
  type        = list(string)
  default     = []
}

variable "sqs_queue" {
  description = "specify sqs queue URL and ARN, do not generate new queue"
  type        = map(string)
  default = {
    arn = ""
    url = ""
  }
}

variable "extraction_secrets" {
  description = "The secrets to be passed to the container."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "extraction_image" {
  description = "override extraction image"
  type        = string
  default     = ""
}

variable "ssm_docker" {
  type = string
}

variable "extraction_environment_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "extraction_buckets_arn" {
  type = list(string)
}

