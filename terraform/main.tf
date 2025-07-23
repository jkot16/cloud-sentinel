provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "cloud_sentinel" {
  bucket = "cloud-sentinel"
  force_destroy = true

  tags = {
    Project = "Cloud Sentinel"
    Owner= "Jakub"
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_sentinel_block" {
  bucket = aws_s3_bucket.cloud_sentinel.id
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloud_sentinel_lifecycle" {
  bucket = aws_s3_bucket.cloud_sentinel.id

  rule {
    id = "delete_old_backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
