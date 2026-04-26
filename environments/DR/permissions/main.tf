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
  name = "go-app-dynamodb-policy-dr"

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
  name = "go-app-sqs-policy-dr"

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
  name = "go-app-ssm-policy-dr"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/dr/app/*"
      },
    ]
  })
}

# ── ESO IRSA ────────────────────────────────────────────────────────────────
# ESO uses its own IRSA role to read SSM — separate from the go-app role.

resource "aws_iam_policy" "eso_ssm" {
  name = "eso-ssm-policy-dr"

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
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/dr/app/*"
      },
    ]
  })
}

module "eso_irsa" {
  source = "../../../modules/irsa"

  role_name         = "eso-irsa-dr"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_provider     = local.oidc_issuer
  namespace         = "external-secrets"
  service_account   = "external-secrets"

  policy_arns = [aws_iam_policy.eso_ssm.arn]
}

# ── go-app IRSA ──────────────────────────────────────────────────────────────

module "irsa" {
  source = "../../../modules/irsa"

  role_name         = "go-app-irsa-dr"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_provider     = local.oidc_issuer
  namespace         = var.app_namespace
  service_account   = var.app_service_account

  policy_arns = [
    aws_iam_policy.go_app_dynamodb.arn,
    aws_iam_policy.go_app_sqs.arn,
    aws_iam_policy.go_app_ssm.arn,
  ]
}
