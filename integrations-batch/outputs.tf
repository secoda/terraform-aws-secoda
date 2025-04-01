output "integration_environment" {
  description = "Environment string used in naming"
  value       = var.environment
}

output "function_s3_bucket" {
  description = "S3 bucket ID for worker integration functions."
  value       = aws_s3_bucket.integration_functions_bucket.id
}

output "output_s3_bucket" {
  description = "S3 bucket ID for worker integration run output."
  value       = aws_s3_bucket.integration_output_bucket.id
}

output "batch_job_queue" {
  description = "Name of integrations the batch job queue."
  value       = aws_batch_job_queue.integration_queue.name
}

output "batch_job_definition" {
  description = "Name of integrations the batch job definition."
  value       = aws_batch_job_definition.integration_run.name
}

output "result_sqs_url" {
  description = "URL of SQS that receives finished job messages."
  value       = local.sqs_queue.url
}

output "result_sqs_arn" {
  description = "URL of SQS that receives finished job messages."
  value       = local.sqs_queue.arn
}

output "encryption_token_arn" {
  description = "ARN of the batch job parameter encryption token."
  value       = aws_secretsmanager_secret.encryption_token.arn
}

# Extractions
output "extraction_function_s3_bucket" {
  description = "S3 bucket ID for worker extraction functions."
  value       = aws_s3_bucket.extraction_functions_bucket.id
}

output "extraction_output_s3_bucket" {
  description = "S3 bucket ID for worker extraction run output."
  value       = aws_s3_bucket.extraction_output_bucket.id
}

output "extraction_batch_job_queue" {
  description = "Name of extractions the batch job queue."
  value       = aws_batch_job_queue.extraction_queue.name
}

output "extraction_batch_job_definition" {
  description = "Name of extractions the batch job definition."
  value       = aws_batch_job_definition.extraction_run.name
}

output "extraction_result_sqs_url" {
  description = "URL of SQS that receives finished job messages."
  value       = aws_sqs_queue.extraction_batch_sqs.id
}

output "extraction_result_sqs_arn" {
  description = "URL of SQS that receives finished job messages."
  value       = aws_sns_topic.extraction_batch_jobs.arn
}

output "integration_sg_id" {
  description = "integrations and extractions batch security group"
  value       = aws_security_group.integration_batch_full_egress.id
}

output "ecs_vars" {
  description = "output map used for values to initialize ecs"
  value = {
    batch_environment_vars = [
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
        "name" : "INTEGRATION_BATCH_JOB_DEFINITION",
        "value" : aws_batch_job_definition.integration_run.name,
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
        "value" : aws_batch_job_queue.extraction_queue.name,
      },
      {
        "name" : "EXTRACTION_BATCH_JOB_DEFINITION",
        "value" : aws_batch_job_definition.extraction_run.name,
      }
    ]

    batch_ecs_task_iam_statement = [
      {
        sid       = ["sqsBatch"]
        actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        resources = [local.sqs_queue.arn]
      },
      {
        sid       = ["batchManage"]
        actions   = ["batch:Describe*", "batch:List*", "batch:CancelJob", "batch:TerminateJob"]
        resources = ["*"]
      },
      {
        sid     = ["batchJobManage"]
        actions = ["batch:SubmitJob"]
        resources = [
          "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/${aws_batch_job_definition.integration_run.name}*",
          "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-queue/${aws_batch_job_queue.integration_queue.name}",
          "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/${aws_batch_job_definition.extraction_run.name}*",
          "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-queue/${aws_batch_job_queue.extraction_queue.name}"
        ]
      }
    ]

    batch_buckets = [
      "arn:aws:s3:::${aws_s3_bucket.integration_functions_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.integration_functions_bucket.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.integration_output_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.integration_output_bucket.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.extraction_functions_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.extraction_functions_bucket.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.extraction_output_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.extraction_output_bucket.id}/*"
    ]
  }
}

