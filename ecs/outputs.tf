output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including both family and revision)."
  value       = aws_ecs_task_definition.main.arn
}

output "task_definition_family" {
  description = "The family of the Task Definition."
  value       = aws_ecs_task_definition.main.family
}

output "awslogs_group" {
  description = "Name of the CloudWatch Logs log group containers should use."
  value       = local.awslogs_group
}

output "awslogs_group_arn" {
  description = "ARN of the CloudWatch Logs log group containers should use."
  value       = aws_cloudwatch_log_group.main.arn
}

output "ecs_service_id" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.main.id
}

output "aws_lb_dns" {
  description = "DNS name of the load balancer, or null if no ALB is associated"
  value       = try(aws_lb.main[0].dns_name, null)
}

output "aws_lb_zone_id" {
  description = "Zone ID of the load balancer, or null if no ALB is associated"
  value       = try(aws_lb.main[0].zone_id, null)
}

output "aws_lb_arn" {
  description = "ARN of the load balancer, or null if no ALB is associated"
  value       = try(aws_lb.main[0].arn, null)
}