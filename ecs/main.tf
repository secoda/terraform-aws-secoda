data "aws_caller_identity" "current" {}

################################################################################
# Local Variables
################################################################################

# If custom services are not provided, use an empty list.
locals {
  custom_services = var.custom_services != null ? var.custom_services : []
}

################################################################################
# ECS
################################################################################

locals {
  ecs_service_launch_type = "FARGATE"

  volume_name           = "${var.name}-volume"
  awslogs_group         = var.logs_cloudwatch_group == "" ? "/ecs/${var.name}/${var.name}" : var.logs_cloudwatch_group
  target_container_name = var.target_container_name == "" ? "${var.name}" : var.target_container_name
  cloudwatch_alarm_name = var.cloudwatch_alarm_name == "" ? "${var.name}" : var.cloudwatch_alarm_name

  lb_target_groups = [
    {
      container_port              = var.container_port
      container_health_check_port = var.container_port
    }
  ]

  # For each target group, allow ingress from the alb to ecs container port.
  lb_ingress_container_ports = distinct(
    [
      for lb_target_group in local.lb_target_groups : lb_target_group.container_port
    ]
  )

  # For each target group, allow ingress from the alb to ecs healthcheck port.
  # If it doesn't collide with the container ports.
  lb_ingress_container_health_check_ports = tolist(
    setsubtract(
      [
        for lb_target_group in local.lb_target_groups : lb_target_group.container_health_check_port
      ],
      local.lb_ingress_container_ports,
    )
  )

  ecs_service_agg_security_groups = compact(concat(tolist([var.ecs_sg_id]), var.additional_security_group_ids))
}

################################################################################
# Alarms
################################################################################

module "aws-alb-alarms" {
  count = var.associate_alb ? 1 : 0

  source           = "../alarms"
  load_balancer_id = aws_lb.main[0].id
  target_group_id  = aws_lb_target_group.https[0].id
}

################################################################################
# Application Load Balancer
################################################################################

resource "aws_lb" "main" {
  count              = var.associate_alb ? 1 : 0
  name               = substr(var.name, 0, 32) # The name builder is too long.
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg[0].id]
  subnets            = var.ecs_public_subnets
}

resource "aws_lb_listener" "redirect" {
  count             = var.enable_https && var.associate_alb ? 1 : 0
  load_balancer_arn = aws_lb.main[0].id

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_https && var.associate_alb ? 1 : 0

  load_balancer_arn = aws_lb.main[0].id
  certificate_arn   = var.certificate_arn

  port       = 443
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-FS-1-2-Res-2020-10"

  default_action {
    target_group_arn = aws_lb_target_group.https[0].id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "https" {
  count = var.associate_alb ? 1 : 0

  name     = substr(var.name, 0, 32)
  port     = var.container_port
  protocol = "HTTPS"

  vpc_id      = var.ecs_vpc_id
  target_type = "ip"

  deregistration_delay = 90

  health_check {
    timeout             = 15
    interval            = 60
    path                = var.health_check_url
    protocol            = "HTTPS"
    healthy_threshold   = 3
    unhealthy_threshold = 10
    matcher             = "200,302"
  }
}

################################################################################
# Application Load Balancer - Security Groups
################################################################################

resource "aws_security_group" "lb_sg" {
  count = var.associate_alb ? 1 : 0

  name   = "lb-${var.name}"
  vpc_id = var.ecs_vpc_id
}

resource "aws_security_group_rule" "app_lb_allow_outbound" {
  count = var.associate_alb ? 1 : 0

  security_group_id = aws_security_group.lb_sg[0].id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_lb_allow_all_http" {
  count = var.associate_alb ? 1 : 0

  security_group_id = aws_security_group.lb_sg[0].id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_lb_allow_all_https" {
  count = var.associate_alb ? 1 : 0

  security_group_id = aws_security_group.lb_sg[0].id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

################################################################################
# Cloudwatch
################################################################################

resource "aws_cloudwatch_log_group" "main" {
  name              = local.awslogs_group
  retention_in_days = var.logs_cloudwatch_retention
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu" {
  count = var.cloudwatch_alarm_cpu_enable ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-cpu"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_cpu_threshold

  dimensions = {
    "ClusterName" = var.aws_ecs_cluster.name
    "ServiceName" = aws_ecs_service.main.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_mem" {
  count = var.cloudwatch_alarm_mem_enable ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-mem"
  alarm_description = "Monitors ECS memory Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_mem_threshold

  dimensions = {
    "ClusterName" = var.aws_ecs_cluster.name
    "ServiceName" = aws_ecs_service.main.name
  }
}

################################################################################
# Security
################################################################################

resource "aws_security_group_rule" "app_ecs_allow_outbound" {
  description       = "All outbound"
  security_group_id = var.ecs_sg_id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ecs_allow_https_from_alb" {
  count = var.associate_alb ? length(local.lb_ingress_container_ports) : 0

  description       = "Allow in ALB"
  security_group_id = var.ecs_sg_id

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_sg[0].id
}

################################################################################
# IAM - Policy
################################################################################

data "aws_iam_policy_document" "ecs_assume_role_policy" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

################################################################################
# IAM - Task Roles / Policies (used by the task manager)
################################################################################

data "aws_iam_policy_document" "task_execution_role_policy_doc" {

  # Docker hub authentication.
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = ["${var.ssm_docker}"]
  }


  # awslogger
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.main.arn}:*"]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-task-role-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

################################################################################
# IAM - Task Execution Role / Policies (used by the task itself)
################################################################################

resource "aws_iam_role" "task_execution_role" {
  name               = "ecs-task-execution-role-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  name   = "${aws_iam_role.task_execution_role.name}-policy"
  role   = aws_iam_role.task_execution_role.name
  policy = data.aws_iam_policy_document.task_execution_role_policy_doc.json
}

data "aws_iam_policy_document" "task_role_ecs_exec" {

  # S3 Access for manifest files (optional).
  statement {
    sid = "AllowBucketAccess"

    actions = [
      "s3:*",
    ]

    resources = var.s3_resources
  }

  dynamic "statement" {
    for_each = { for v in var.ecs_task_iam_statement : v.sid[0] => v if v.actions[0] != "" }
    content {
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }

  statement {
    sid = "AllowRoleAssumption"

    actions = [
      "sts:AssumeRole",
    ]

    resources = ["*"]
  }


  # ECS exec for debugging
  statement {
    sid = "AllowECSExec"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowDescribeLogGroups"

    actions = [
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowECSExecLogging"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.main.arn}:*"]
  }
}

resource "aws_iam_policy" "task_role_ecs_exec" {
  name        = "${aws_iam_role.task_role.name}-ecs-exec"
  description = "Allow ECS Exec with Cloudwatch logging when attached to an ECS task role"
  policy      = join("", data.aws_iam_policy_document.task_role_ecs_exec.*.json)
}

resource "aws_iam_role_policy_attachment" "task_role_ecs_exec" {
  role       = join("", aws_iam_role.task_role.*.name)
  policy_arn = join("", aws_iam_policy.task_role_ecs_exec.*.arn)
}

################################################################################
# ECS - Service
################################################################################

resource "aws_ecs_service" "main" {
  name    = var.name
  cluster = var.aws_ecs_cluster.arn

  launch_type            = local.ecs_service_launch_type
  enable_execute_command = true

  # Use latest active revision
  task_definition = "${aws_ecs_task_definition.main.family}:${max(
    aws_ecs_task_definition.main.revision,
    data.aws_ecs_task_definition.main.revision,
  )}"

  desired_count                      = var.tasks_desired_count
  deployment_minimum_healthy_percent = var.tasks_minimum_healthy_percent
  deployment_maximum_percent         = var.tasks_maximum_percent

  # If you cannot connect outbound to the internet from a task, make sure that the EC2 machine, service, and task are being run in the private subnet.
  # Counterintuitive, but the tasks must be routed outwards through the NAT gateway.
  network_configuration {
    subnets          = var.ecs_private_subnets
    security_groups  = local.ecs_service_agg_security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.associate_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.https[0].arn
      container_name   = local.target_container_name
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = var.health_check_grace_period_seconds
}

################################################################################
# Task Definition (ECS)
################################################################################

resource "random_uuid" "api_secret" {}

resource "tls_private_key" "jwt" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_ecs_task_definition" "main" {
  family             = var.name
  network_mode       = "awsvpc"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn

  requires_compatibilities = ["FARGATE"]

  runtime_platform {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = "LINUX"
  }

  ephemeral_storage {
    size_in_gib = 100
  }

  cpu    = var.total_cpu
  memory = var.total_memory

  # Use the `nonsensitive()` operator to view the diff in case of unknown `force replacement`.
  container_definitions = (jsonencode(
    concat(
      [for service in var.core_services :
        merge(
          ({
            for key, value in service :
            key => value
            if value != null
          }),
          {
            name  = service.name
            image = "${var.repository_prefix}-${service.name}:${var.tag}"

            "repositoryCredentials" = {
              "credentialsParameter" : "${var.ssm_docker}"
            }

            cpu               = floor(floor((var.total_cpu - try(sum([for s in local.custom_services : s.cpu]), 0)) * service.preferred_cpu_percentage / 100) / 128) * 128
            memoryReservation = floor(floor((var.total_memory - try(sum([for s in local.custom_services : s.memoryReservation]), 0)) * service.preferred_memory_percentage / 100) / 128) * 128
            essential         = tobool(service.essential)

            requires_compatibilities = ["FARGATE"]

            linuxParameters = {
              initProcessEnabled = true
            }

            portMappings = [for port in service.ports :
              {
                containerPort = tonumber(port)
                hostPort      = tonumber(port)
                protocol      = "tcp"
              }
            ]

            environment = flatten([service.environment,
              {
                "name" : "ES_HOST",
                "value" : var.es_host,
              },
              {
                "name" : "ES_USERNAME",
                "value" : "elastic",
              },
              {
                "name" : "ES_PASSWORD",
                "value" : var.es_password,
              },
              {
                "name" : "APISERVICE_SECRET",
                "value" : var.api_secret == "" ? random_uuid.api_secret.result : var.api_secret
              },
              {
                name  = "PRIVATE_KEY",
                value = var.private_key == "" ? base64encode(tls_private_key.jwt.private_key_pem) : var.private_key 
              },
              {
                name  = "PUBLIC_KEY",
                value = var.public_key== "" ? base64encode(tls_private_key.jwt.public_key_pem) : var.public_key
              },
              {
                "name" : "PRIVATE_BUCKET", # This is where all the private files will be stored.
                "value" : var.private_bucket,
              },
              {
                "name" : "REDIS_URL",
                "value" : "redis://${var.redis_addr}:6379",
              },
              {
                "name" : "APISERVICE_DATABASE_CONNECTION",
                "value" : "postgresql://keycloak:${var.keycloak_database_password}@${var.db_addr}:5432/secoda",
              },
              {
                "name" : "AWS_ACCOUNT_ID",
                "value" : data.aws_caller_identity.current.account_id,
              },
              var.add_environment_vars,
            ])

            command = service.command

            dependsOn = service.dependsOn

            healthCheck = service.healthCheck

            mountPoints = service.mountPoints != null ? service.mountPoints : []

            volumesFrom = []

            ulimits = [
              {
                "name" : "core"
                "softLimit" : 0
                "hardLimit" : 0
              }
            ]

            logConfiguration = {
              logDriver = "awslogs"
              options = {
                "awslogs-group"         = local.awslogs_group
                "awslogs-region"        = var.aws_region
                "awslogs-stream-prefix" = "${service.name}-logs"
              }
            }
          }
        )
      ],
      local.custom_services
    )
  ))

  lifecycle {
    ignore_changes = [
      requires_compatibilities,
      cpu,
      memory,
      execution_role_arn,
    ]
  }
}

# Create a data source to pull the latest active revision from.
data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.main.family
  depends_on      = [aws_ecs_task_definition.main] # Ensures at least one task def exists.
}
