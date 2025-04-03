resource "aws_sns_topic" "extraction_batch_jobs" {
  name = "ext-batch-jobs-${var.environment}"
}

resource "aws_sns_topic_policy" "extraction_default" {
  arn    = aws_sns_topic.extraction_batch_jobs.arn
  policy = data.aws_iam_policy_document.extraction_sns_topic_policy.json
}

data "aws_iam_policy_document" "extraction_sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.extraction_batch_jobs.arn]
  }
}

resource "aws_cloudwatch_event_rule" "extraction_batch_jobs" {
  name        = "ext-batch-status-${var.environment}"
  description = "extraction batch run status"

  event_pattern = jsonencode({
    detail-type = [
      "Batch Job State Change"
    ]
    source = [
      "aws.batch"
    ]
    detail = {
      jobQueue = [
        aws_batch_job_queue.extraction_queue.arn
      ]
      status = [
        "FAILED",
        "SUCCEEDED"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "extraction_batch_sns" {
  rule      = aws_cloudwatch_event_rule.extraction_batch_jobs.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.extraction_batch_jobs.arn
}

resource "aws_sqs_queue" "extraction_batch_sqs" {
  name                      = "ext-batch-notify-${var.environment}"
  receive_wait_time_seconds = 20
  message_retention_seconds = 18400
}

resource "aws_sqs_queue_policy" "extraction_batch_sqs_subscription" {
  queue_url = aws_sqs_queue.extraction_batch_sqs.id
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
        "${aws_sqs_queue.extraction_batch_sqs.id}"
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

resource "aws_sns_topic_subscription" "extraction_batch_sqs_subscription" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = aws_sns_topic.extraction_batch_jobs.arn
  endpoint             = aws_sqs_queue.extraction_batch_sqs.arn
}

resource "aws_cloudwatch_metric_alarm" "extraction_sqs_message_age" {
  alarm_name        = "${var.name_ext}-${var.environment}-sqs-message-age"
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
    "QueueName" = aws_sqs_queue.extraction_batch_sqs.name
  }
}

