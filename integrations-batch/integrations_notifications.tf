locals {
  sqs_queue = var.sqs_queue.arn == "" ? { arn = aws_sqs_queue.integration_batch_sqs[0].arn, url = aws_sqs_queue.integration_batch_sqs[0].id } : { arn = var.sqs_queue.arn, url = var.sqs_queue.url }
}

resource "aws_sns_topic" "integration_batch_jobs" {
  name = "int-batch-jobs-${var.environment}"
}

resource "aws_sns_topic_policy" "integration_default" {
  arn    = aws_sns_topic.integration_batch_jobs.arn
  policy = data.aws_iam_policy_document.integration_sns_topic_policy.json
}

data "aws_iam_policy_document" "integration_sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.integration_batch_jobs.arn]
  }
}

resource "aws_cloudwatch_event_rule" "integration_batch_jobs" {
  name        = "int-batch-status-${var.environment}"
  description = "integration batch run status"

  event_pattern = jsonencode({
    detail-type = [
      "Batch Job State Change"
    ]
    source = [
      "aws.batch"
    ]
    detail = {
      jobQueue = [
        aws_batch_job_queue.integration_queue.arn
      ]
      status = [
        "FAILED",
        "SUCCEEDED"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "integration_batch_sns" {
  rule      = aws_cloudwatch_event_rule.integration_batch_jobs.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.integration_batch_jobs.arn
}

resource "aws_sqs_queue" "integration_batch_sqs" {
  count                     = var.sqs_queue.arn == "" ? 1 : 0
  name                      = "int-batch-notify-${var.environment}"
  receive_wait_time_seconds = 20
  message_retention_seconds = 18400
}

resource "aws_sqs_queue_policy" "integration_batch_sqs_subscription" {
  queue_url = local.sqs_queue.url
  policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "${local.sqs_queue.arn}"
      ],
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }
  ]
}
EOF
}

resource "aws_sns_topic_subscription" "integration_batch_sqs_subscription" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = aws_sns_topic.integration_batch_jobs.arn
  endpoint             = local.sqs_queue.arn
}

resource "aws_cloudwatch_metric_alarm" "sqs_message_age" {
  count             = var.sqs_queue.arn == "" ? 1 : 0
  alarm_name        = "${var.name}-${var.environment}-sqs-message-age"
  alarm_description = "Monitors SQS queue message age"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "3600"
  statistic           = "Maximum"
  threshold           = var.cloudwatch_alarm_sqs_age_threshold

  dimensions = {
    "QueueName" = aws_sqs_queue.integration_batch_sqs[0].name
  }
}

