output "github_actions_role_arn" {
  description = "IAM role used by GitHub Actions"
  value       = aws_iam_role.github_actions_role.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "sops_kms_key_arn" {
  description = "KMS key ARN for SOPS — use this in .sops.yaml"
  value       = aws_kms_key.sops.arn
}