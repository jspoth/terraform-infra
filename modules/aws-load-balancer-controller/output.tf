output "role_arn" {
  description = "ARN of the IRSA role for the AWS Load Balancer Controller"
  value       = module.irsa.role_arn
}
