variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "resource_suffix" {
  type        = string
  description = "Suffix appended to IAM policy and role names to avoid conflicts across clusters"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the cluster is deployed"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider" {
  type        = string
  description = "OIDC provider URL without https://"
}
