locals {
  extraction_batch_environment = [
    {
      "name"  = "S3_FUNCTION_BUCKET",
      "value" = aws_s3_bucket.extraction_functions_bucket.id
    },
    {
      "name"  = "S3_OUTPUT_BUCKET",
      "value" = aws_s3_bucket.extraction_output_bucket.id
    },
    {
      "name" : "INTEGRATION_INTEGRATION_SCRIPT_BUCKET",
      "value" : aws_s3_bucket.integration_functions_bucket.id,
    },
    {
      "name" : "INTEGRATION_RESULT_BUCKET",
      "value" : aws_s3_bucket.integration_output_bucket.id,
    },
    {
      "name" : "INTEGRATION_RESULT_SQS_URL",
      "value" : local.sqs_queue.url,
    },
    {
      "name" : "INTEGRATION_BATCH_JOB_QUEUE",
      "value" : aws_batch_job_queue.integration_queue.name,
    },
    {
      "name" : "EXTRACTION_SCRIPT_BUCKET",
      "value" : aws_s3_bucket.extraction_functions_bucket.id,
    },
    {
      "name" : "EXTRACTION_RESULT_BUCKET",
      "value" : aws_s3_bucket.extraction_output_bucket.id,
    },
    {
      "name" : "EXTRACTION_RESULT_SQS_URL",
      "value" : aws_sqs_queue.extraction_batch_sqs.id,
    },
    {
      "name" : "EXTRACTION_BATCH_JOB_QUEUE",
      "value" : aws_batch_job_queue.integration_queue.name,
    },
    {
      "name" : "EXTRACTION_BATCH_JOB_DEFINITION",
      "value" : "THIS",
    }
  ]

  extractions_batch_secrets = []
}
data "aws_iam_policy_document" "extraction_ecs_assume_role_policy" {
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

resource "aws_iam_policy" "extraction_container_logging_policy" {
  name        = "${var.environment}-ext-batch-container-logging"
  path        = "/"
  description = "Allow logging from containers"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "logs:DescribeLogGroups",
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "AllowDescribeLogGroups"
      },
      {
        "Action" : [
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:CreateLogStream"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_cloudwatch_log_group.extraction_batch_log_group.arn}:*",
        "Sid" : "AllowECSExecLogging"
      }
    ]
  })
}

resource "aws_iam_policy" "extraction_allow_assume_role" {
  name        = "${var.environment}-ext-batch-exec-allow-assume-role"
  path        = "/"
  description = "Allow batch worker to assume any role"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "AllowAssumeRoleAccess"
      }
    ]
  })
}

resource "aws_iam_policy" "extraction_ecs_execution_secret_acess" {
  name        = "${var.environment}-ext-batch-exec-secret-access"
  path        = "/"
  description = "Allow access to secrets for task env vars"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "secretsmanager:GetSecretValue",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/*",
          "${var.ssm_docker}"
        ],
        "Sid" : "AllowSecretAccess"
      }
    ]
  })
}

resource "aws_iam_role" "extraction_ecs_execution_role" {
  name               = "ext_batch_exec_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.extraction_ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "extraction_ecs_execution_role_policy" {
  role       = aws_iam_role.extraction_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "extraction_ecs_execution_secret_acess" {
  role       = aws_iam_role.extraction_ecs_execution_role.name
  policy_arn = aws_iam_policy.extraction_ecs_execution_secret_acess.arn
}


resource "aws_iam_role" "extraction_ecs_job_role" {
  name               = "ext_batch_job_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.extraction_ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "extraction_ecs_job_role_policy" {
  role       = aws_iam_role.extraction_ecs_job_role.name
  policy_arn = aws_iam_policy.extraction_buckets_runner_policy.arn
}
resource "aws_iam_role_policy_attachment" "extraction_ecs_job_role_policy1" {
  role       = aws_iam_role.extraction_ecs_job_role.name
  policy_arn = aws_iam_policy.extraction_allow_assume_role.arn
}
resource "aws_iam_role_policy_attachment" "extraction_ecs_job_role_policy2" {
  role       = aws_iam_role.extraction_ecs_job_role.name
  policy_arn = aws_iam_policy.extraction_container_logging_policy.arn
}


resource "aws_batch_job_definition" "extraction_run" {
  name = "ext_batch_job_definition_${var.environment}"
  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    image = var.extraction_image

    "repositoryCredentials" = {
      "credentialsParameter" : "${var.ssm_docker}"
    }

    jobRoleArn = aws_iam_role.extraction_ecs_job_role.arn

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    runtimePlatform = {
      cpuArchitecture = var.cpu_architecture,
    }

    environment = concat(var.extraction_environment_vars, local.extraction_batch_environment)
    secrets     = concat(var.extraction_secrets, local.extractions_batch_secrets)

    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.25"
      },
      {
        type  = "MEMORY"
        value = "512"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.extraction_batch_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = var.environment
        awslogs-create-group  = "true"
      }
    }

    executionRoleArn = aws_iam_role.extraction_ecs_execution_role.arn
    enableExecuteCommand = true
  })
}


