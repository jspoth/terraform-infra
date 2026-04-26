provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

resource "aws_s3_bucket" "tfstate_dr" {
  provider = aws.dr
  bucket   = var.tfstate_bucket_dr

  tags = {
    Name = var.tfstate_bucket_dr
    env  = "dr"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.tfstate_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.tfstate_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_dr" {
  provider                = aws.dr
  bucket                  = aws_s3_bucket.tfstate_dr.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
