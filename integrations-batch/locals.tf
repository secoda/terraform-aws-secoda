locals {
  awslogs_group             = "/ecs/${var.environment}/${var.name}"
  cloudwatch_alarm_name     = "${var.name}-${var.environment}"
  ecs_cluster_name          = "${var.name}-${var.environment}"
  awslogs_group_ext         = "/ecs/${var.environment}/${var.name_ext}"
  cloudwatch_alarm_name_ext = "${var.name_ext}-${var.environment}"
  ecs_cluster_name_ext      = "${var.name_ext}-${var.environment}"
}
