resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}


resource "aws_iam_role_policy" "github_actions_iam_bridge" {
  name = "github-actions-iam-bridge"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRolePolicies",         # <--- ADD THIS
          "iam:GetRolePolicy",            # <--- ADD THIS
          "iam:ListAttachedRolePolicies", # <--- ADD THIS (Highly recommended)
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:GetPolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:GetPolicyVersion"
        ]
        Resource = "*"
      }
    ]
  })
}