variable "role_name" {
  type        = string
  description = "Name of the IAM role"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider" {
  type        = string
  description = "OIDC provider URL without https://"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the service account"
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account name"
}

variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the role"
}