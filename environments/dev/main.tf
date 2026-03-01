module "vpc" {
  source = "../../modules/vpc"

  name           = "dev-vpc"
  cidr_block     = var.cidr_block
  public_subnets = var.public_subnets
  azs            = var.azs
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "dev-eks-cluster"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids

  eks_managed_node_groups = {
    dev_nodes = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

# module "karpenter" {
#   source       = "../../modules/karpenter"
#   cluster_name = module.eks.cluster_name
#   subnet_ids   = module.vpc.private_subnets
# }

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}