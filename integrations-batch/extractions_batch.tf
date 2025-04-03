data "aws_iam_policy_document" "extraction_ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "extraction_ecs_instance_role" {
  name               = "ext_batch_ecs_instance_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.extraction_ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "extraction_ecs_instance_policy" {
  role       = aws_iam_role.extraction_ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "extraction_ecs_instance_profile" {
  name = "ext_batch_ecs_instance_profile_${var.environment}"
  role = aws_iam_role.extraction_ecs_instance_role.name
}

data "aws_iam_policy_document" "extraction_batch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "extraction_aws_batch_service_role" {
  name               = "ext_batch_service_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.extraction_batch_assume_role.json
}

resource "aws_iam_role_policy_attachment" "extraction_aws_batch_service_role_attachment" {
  role       = aws_iam_role.extraction_aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "extraction_batch" {
  compute_environment_name = "ext-batch-${var.environment}"

  compute_resources {
    max_vcpus = var.extraction_vcpu

    security_group_ids = [
      aws_security_group.integration_batch_full_egress.id
    ]

    subnets = var.integration_subnets

    type = "FARGATE"
  }

  service_role = aws_iam_role.extraction_aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.extraction_aws_batch_service_role_attachment]
}

resource "aws_batch_job_queue" "extraction_queue" {
  name     = "ext-batch-job-queue-${var.environment}"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 0
    compute_environment = aws_batch_compute_environment.extraction_batch.arn
  }
}
