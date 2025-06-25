output "aws_lb_dns" {
  description = "The load balancer url. This will start returning HTTP 200 approx. 5 minutes after the terraform is deployed."
  value       = module.ecs.aws_lb_dns
}

output "aws_lb_zone_id" {
  description = "The zone id of the load balancer."
  value       = module.ecs.aws_lb_zone_id
}

output "integration_sg_id" {
  description = "Integration batch security group"
  value       = var.batch_enabled ? module.integrations[0].integration_sg_id : ""
}

output "aws_lb_arn" {
  description = "The ARN of the load balancer."
  value       = module.ecs.aws_lb_arn
}

output "security_group_id" {
  description = "ECS security group ID used for Secoda"
  value       = aws_security_group.ecs_sg.id
}

output "vpc_id" {
  description = "VPC ID used for Secoda"
  value       = length(module.vpc) > 0 ? module.vpc[0].vpc_id : ""
}

output "azs" {
  description = "Availability zones used for Secoda"
  value       = length(module.vpc) > 0 ? module.vpc[0].azs : []
}

output "public_subnet_ids" {
  description = "Subnet IDs used for Secoda"
  value       = length(module.vpc) > 0 ? module.vpc[0].public_subnets : []
}

output "private_subnet_ids" {
  description = "Subnet IDs used for Secoda"
  value       = length(module.vpc) > 0 ? module.vpc[0].private_subnets : []
}

output "private_route_table_ids" {
  description = "Private route table IDs used for Secoda"
  value       = length(module.vpc) > 0 ? module.vpc[0].private_route_table_ids : []
}

output "public_route_table_ids" {
  description = "Public route table IDs used for Secoda"
  value       = length(module.vpc) > 0 ? module.vpc[0].public_route_table_ids : []
}

