module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "dev-eks-cluster"
  cluster_version = "1.27"

  vpc_id     = "vpc-0301e2afaf3bafbb0"
  subnet_ids = ["subnet-03dedde9362f3bd1a"]  # use your public subnet

  # Optional: manage node group
  node_groups = {
    dev_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.micro"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = var.cluster_name
  kubernetes_version = "1.31"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  # Use this block to define your nodes directly
  eks_managed_node_groups = {
    # This is your "Bootstrap/System" group
    dev_nodes = {
      ami_type       = "AL2023_x86_64_STANDARD" # Recommended for K8s 1.31
      instance_types = ["t3.small"]             # t3.micro is often too small for EKS system pods

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # STAFF TIP: Taint these so your "Consumers" don't crowd out system pods
      taints = {
        dedicated = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  # Required for the transition to modern EKS access management
  authentication_mode = "API_AND_CONFIG_MAP"
}