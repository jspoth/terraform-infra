module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  # Use the variables from your root main.tf
  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Critical for local access & Karpenter setup
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = {
    dev_nodes = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"] # t3.micro is too small for 1.31 system pods

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Ensures this group is only for Karpenter and system pods
      taints = {
        dedicated = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  # Modern EKS access management (Required for v21+)
  authentication_mode = "API_AND_CONFIG_MAP"

  # Adds your current local user as a cluster admin automatically
  enable_cluster_creator_admin_permissions = true
}
