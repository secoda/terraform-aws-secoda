#
# IAM - task
#

data "aws_iam_policy_document" "ecs_assume_role_policy" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    /*
    condition {
      test = "ArnLike"
      variable = "aws:SourceArn"
      values = ["arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    }

    condition {
      test = "StringEquals"
      variable = "aws:SourceAccount"
      values = ["${data.aws_caller_identity.current.account_id}"]
    }
    */
  }
}

data "aws_iam_policy_document" "task_role_policy_doc" {

  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [aws_kms_key.integration.arn]
  }

}

data "aws_iam_policy_document" "task_execution_role_policy_doc" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/*",
      "${var.ssm_docker}"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.integration.arn}:*",
      "${aws_cloudwatch_log_group.extraction.arn}:*"
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [aws_kms_key.integration.arn]
  }

}

#
# Task Role
#
resource "aws_iam_role" "task_role" {
  name               = "${var.name}-${var.environment}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_role_policy" {
  name   = "${aws_iam_role.task_role.name}-pol"
  role   = aws_iam_role.task_role.name
  policy = data.aws_iam_policy_document.task_role_policy_doc.json
}

#
# Task Execution Role
#

resource "aws_iam_role" "task_execution_role" {
  name               = "${var.name}-${var.environment}-ecs-task-exc"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  name   = "${aws_iam_role.task_execution_role.name}-pol"
  role   = aws_iam_role.task_execution_role.name
  policy = data.aws_iam_policy_document.task_execution_role_policy_doc.json
}


#
# Task Role Extraction
#
resource "aws_iam_role" "task_role_extraction" {
  name               = "${var.name_ext}-${var.environment}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_role_policy_extraction" {
  name   = "${aws_iam_role.task_role_extraction.name}-pol"
  role   = aws_iam_role.task_role_extraction.name
  policy = data.aws_iam_policy_document.task_role_policy_doc.json
}

#
# Task Execution Role Extraction
#

resource "aws_iam_role" "task_execution_role_extraction" {
  name               = "${var.name_ext}-${var.environment}-ecs-task-exc"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_execution_role_policy_extraction" {
  name   = "${aws_iam_role.task_execution_role_extraction.name}-pol"
  role   = aws_iam_role.task_execution_role_extraction.name
  policy = data.aws_iam_policy_document.task_execution_role_policy_doc.json
}

#
# ECS Exec
#

data "aws_iam_policy_document" "task_role_ecs_exec" {
  statement {
    sid    = "AllowECSExec"
    effect = "Allow"

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
    resources = [
      "${aws_cloudwatch_log_group.integration.arn}:*",
      "${aws_cloudwatch_log_group.extraction.arn}:*"
    ]
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

resource "aws_iam_policy" "task_role_ecs_exec_extraction" {
  name        = "${aws_iam_role.task_role_extraction.name}-ecs-exec"
  description = "Allow ECS Exec with Cloudwatch logging when attached to an ECS task role"
  policy      = join("", data.aws_iam_policy_document.task_role_ecs_exec.*.json)
}

resource "aws_iam_role_policy_attachment" "task_role_ecs_exec_extraction" {
  role       = join("", aws_iam_role.task_role_extraction.*.name)
  policy_arn = join("", aws_iam_policy.task_role_ecs_exec_extraction.*.arn)
}


