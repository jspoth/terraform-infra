data "aws_caller_identity" "current" {}

resource "aws_kms_key" "sops" {
  description             = "SOPS encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  lifecycle {
    prevent_destroy = true
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM root access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow GitHub Actions to use SOPS key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.github_actions_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "sops" {
  name          = "alias/dev-sops"
  target_key_id = aws_kms_key.sops.key_id
}
