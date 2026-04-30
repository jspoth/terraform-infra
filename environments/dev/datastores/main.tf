data "aws_caller_identity" "current" {}

module "dynamodb" {
  source = "../../../modules/dynamodb"

  table_name     = var.table_name
  replica_region = var.replica_region
  tags           = var.tags
}

resource "aws_ssm_parameter" "dynamodb_table_name" {
  name  = "/dev/app/dynamodb/table-name"
  type  = "String"
  value = module.dynamodb.table_name
  tags  = var.tags
}

# ── Cost Optimizer Tables ─────────────────────────────────────────────────────

resource "aws_dynamodb_table" "cost_optimizer_jobs" {
  name         = "cost-optimizer-jobs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = var.tags
}

resource "aws_dynamodb_table" "cost_optimizer_findings" {
  name         = "cost-optimizer-findings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = var.tags
}

# ── S3 Reports Bucket ─────────────────────────────────────────────────────────

resource "aws_s3_bucket" "cost_optimizer_reports" {
  bucket = "cost-optimizer-reports-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "cost_optimizer_reports" {
  bucket = aws_s3_bucket.cost_optimizer_reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cost_optimizer_reports" {
  bucket = aws_s3_bucket.cost_optimizer_reports.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cost_optimizer_reports" {
  bucket                  = aws_s3_bucket.cost_optimizer_reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

