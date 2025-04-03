/* Buckets */
resource "aws_s3_bucket" "extraction_output_bucket" {
  bucket = "${var.environment}-ext-batch-output"
}

resource "aws_s3_bucket" "extraction_functions_bucket" {
  bucket = "${var.environment}-ext-batch-functions"
}

/* Bucket Public Access */
resource "aws_s3_bucket_public_access_block" "extraction_output_bucket_access" {
  bucket = aws_s3_bucket.extraction_output_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "extraction_functions_bucket_access" {
  bucket = aws_s3_bucket.extraction_output_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/* Bucket Ownership Controls */
resource "aws_s3_bucket_ownership_controls" "extraction_output_bucket_ownership" {
  bucket = aws_s3_bucket.extraction_output_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "extraction_functions_bucket_ownership" {
  bucket = aws_s3_bucket.extraction_output_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

/* Bucket Lifecycle */
resource "aws_s3_bucket_lifecycle_configuration" "extraction_output_bucket_lifecycle" {
  bucket = aws_s3_bucket.extraction_output_bucket.id
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
resource "aws_iam_policy" "extraction_buckets_rw_policy" {
  name        = "${var.environment}-ext-batch-buckets-rw"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "extractionBucketsRw",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : concat(
          [
            "arn:aws:s3:::${aws_s3_bucket.extraction_output_bucket.id}/*",
            "arn:aws:s3:::${aws_s3_bucket.extraction_output_bucket.id}",
            "arn:aws:s3:::${aws_s3_bucket.extraction_functions_bucket.id}/*",
            "arn:aws:s3:::${aws_s3_bucket.extraction_functions_bucket.id}"
          ],
          var.extraction_buckets_arn
        )
      }
    ]
  })
}
/* Read only/write only policy */
resource "aws_iam_policy" "extraction_buckets_runner_policy" {
  name        = "${var.environment}-ext-batch-buckets-runner"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "extractionBucketWo",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.extraction_output_bucket.id}/*"
        ]
      },
      {
        "Sid" : "extractionFunctiounsRo",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.extraction_functions_bucket.id}/*"
        ]
      },
      {
        "Sid" : "privateBucketsRw",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : var.extraction_buckets_arn
      }
    ]
  })
}

