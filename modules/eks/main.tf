module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  # Use the variables from your root main.tf
  name              = var.cluster_name
  kubernetes_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  # Critical for local access & Karpenter setup
  endpoint_public_access = true

  addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = var.eks_managed_node_groups

  # Modern EKS access management (Required for v21+)
  authentication_mode = "API_AND_CONFIG_MAP"

  # Adds your current local user as a cluster admin automatically
  enable_cluster_creator_admin_permissions = true
}


