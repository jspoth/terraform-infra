variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name — used to look up OIDC provider for IRSA trust policies"
}

variable "app_namespace" {
  type        = string
  description = "Kubernetes namespace the go-app service account lives in"
  default     = "default"
}

variable "app_service_account" {
  type        = string
  description = "Kubernetes service account name for the go-app"
  default     = "go-app-sa"
}

variable "sqs_queue_prefix" {
  type        = string
  description = "Name prefix for SQS queues (e.g. 'dev'). Policy grants access to all queues matching <prefix>-*. Add queues in messaging/terraform.tfvars — no changes needed here."
  default     = "dev"
}
