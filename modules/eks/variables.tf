variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "The Kubernetes version for the cluster"
  default     = "1.27"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where EKS will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to launch EKS nodes in"
}

variable "node_groups" {
  type = map(object({
    desired_capacity = number
    max_capacity     = number
    min_capacity     = number
    instance_type    = string
  }))
  description = "Map of node group configurations"
  default     = {}
}