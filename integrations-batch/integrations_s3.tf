/* Buckets */
resource "aws_s3_bucket" "integration_output_bucket" {
  bucket = "${var.environment}-int-batch-output"
}

resource "aws_s3_bucket" "integration_functions_bucket" {
  bucket = "${var.environment}-int-batch-functions"
}

/* Bucket Public Access */
resource "aws_s3_bucket_public_access_block" "integration_output_bucket_access" {
  bucket = aws_s3_bucket.integration_output_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "integration_functions_bucket_access" {
  bucket = aws_s3_bucket.integration_output_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/* Bucket Ownership Controls */
resource "aws_s3_bucket_ownership_controls" "integration_output_bucket_ownership" {
  bucket = aws_s3_bucket.integration_output_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "integration_functions_bucket_ownership" {
  bucket = aws_s3_bucket.integration_output_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

/* Bucket Lifecycle */
resource "aws_s3_bucket_lifecycle_configuration" "integration_output_bucket_lifecycle" {
  bucket = aws_s3_bucket.integration_output_bucket.id
  rule {
    status = "Enabled"
    id     = "expire_all_files"
    expiration {
      days = 30
    }
  }
}

/* IAM bucket policies */
/* Full Control Policy */
resource "aws_iam_policy" "integration_buckets_rw_policy" {
  name        = "${var.environment}-int-batch-buckets-rw"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "integrationBucketsRw",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.integration_output_bucket.id}/*",
          "arn:aws:s3:::${aws_s3_bucket.integration_output_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.integration_functions_bucket.id}/*",
          "arn:aws:s3:::${aws_s3_bucket.integration_functions_bucket.id}"
        ]
      }
    ]
  })
}
/* Read only/write only policy */
resource "aws_iam_policy" "integration_buckets_runner_policy" {
  name        = "${var.environment}-int-batch-buckets-runner"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "integrationBucketWo",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.integration_output_bucket.id}/*"
        ]
      },
      {
        "Sid" : "integrationFunctiounsRo",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.integration_functions_bucket.id}/*"
        ]
      }
    ]
  })
}

