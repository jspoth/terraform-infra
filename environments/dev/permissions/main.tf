data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

locals {
  oidc_issuer       = trimprefix(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://")
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer}"
}

# ── DynamoDB ────────────────────────────────────────────────────────────────

data "aws_dynamodb_table" "app_events" {
  name = "app_events"
}

resource "aws_iam_policy" "go_app_dynamodb" {
  name = "go-app-dynamodb-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateTable",
        ]
        Resource = data.aws_dynamodb_table.app_events.arn
      },
    ]
  })
}

# ── SQS ─────────────────────────────────────────────────────────────────────
# Queue creation is Terraform-only — add new queues in messaging/terraform.tfvars.
# This wildcard policy covers all queues matching the prefix, so no changes
# are needed here when new queues are added.

resource "aws_iam_policy" "go_app_sqs" {
  name = "go-app-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${var.sqs_queue_prefix}-*"
      },
    ]
  })
}

# ── SSM ─────────────────────────────────────────────────────────────────────
# App reads config from SSM at runtime — no env vars needed in CI/CD.
# Wildcard scoped to /dev/app/* covers all params written by datastores/ and messaging/.

resource "aws_iam_policy" "go_app_ssm" {
  name = "go-app-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/dev/app/*"
      },
    ]
  })
}

# ── ESO IRSA ────────────────────────────────────────────────────────────────
# ESO uses its own IRSA role to read SSM — separate from the go-app role.

resource "aws_iam_policy" "eso_ssm" {
  name = "eso-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/dev/app/*"
      },
    ]
  })
}

module "eso_irsa" {
  source = "../../../modules/irsa"

  role_name         = "eso-irsa-dev"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_provider     = local.oidc_issuer
  namespace         = "external-secrets"
  service_account   = "external-secrets"

  policy_arns = [aws_iam_policy.eso_ssm.arn]
}

# ── Cost Optimizer IAM ───────────────────────────────────────────────────────

data "aws_s3_bucket" "cost_optimizer_reports" {
  bucket = "cost-optimizer-reports-${data.aws_caller_identity.current.account_id}"
}

data "aws_sns_topic" "cost_optimizer_alerts" {
  name = "dev-cost-optimizer-alerts"
}

resource "aws_iam_policy" "cost_optimizer" {
  name = "cost-optimizer-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = [
          "arn:aws:bedrock:${var.region}::foundation-model/*",
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ce:GetCostAndUsage"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["pricing:GetProducts"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = data.aws_sns_topic.cost_optimizer_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GeneratePresignedUrl",
        ]
        Resource = "${data.aws_s3_bucket.cost_optimizer_reports.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "elasticloadbalancing:Describe*",
          "eks:DescribeCluster",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/cost-optimizer-jobs",
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/cost-optimizer-findings",
        ]
      },
    ]
  })
}

module "irsa" {
  source = "../../../modules/irsa"

  role_name         = "go-app-irsa-primary"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_provider     = local.oidc_issuer
  namespace         = var.app_namespace
  service_account   = var.app_service_account

  policy_arns = [
    aws_iam_policy.go_app_dynamodb.arn,
    aws_iam_policy.go_app_sqs.arn,
    aws_iam_policy.go_app_ssm.arn,
    aws_iam_policy.cost_optimizer.arn,
  ]
}
