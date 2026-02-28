variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Karpenter to provision nodes in"
}