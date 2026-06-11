# Terraform State Backend S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  provider = aws
  bucket   = var.state_bucket_name
  tags = var.tags
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  provider                = aws
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Versioning (Critical for State Recovery)
resource "aws_s3_bucket_versioning" "terraform_state" {
  provider = aws
  bucket   = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Default Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  provider = aws
  bucket   = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle Rules for Old State Versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  provider = aws
  bucket   = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

# Bucket Policy - Enforce SSL
resource "aws_s3_bucket_policy" "terraform_state" {
  provider = aws
  bucket   = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}",
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
