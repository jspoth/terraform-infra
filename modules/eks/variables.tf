variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "The Kubernetes version for the cluster"
  default     = "1.31" # Upgraded to match our v21.x plan
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where EKS will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to launch EKS nodes in"
}

# Renamed to match the modern module's internal expectations
variable "eks_managed_node_groups" {
  type        = any
  description = "Map of EKS managed node group configurations"
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  type        = bool
  description = "Adds the terraform caller as a cluster admin"
  default     = true
}