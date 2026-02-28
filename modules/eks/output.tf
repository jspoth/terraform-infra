output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_group_arns" {
  description = "ARNs of the EKS managed node groups"
  # This pulls all ARNs from the map of node groups created by the module
  value = [for ng in module.eks.eks_managed_node_groups : ng.node_group_arn]
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}