module "vpc" {
  source = "../../modules/vpc"

  vpc_name        = var.vpc_name
  cidr_block      = var.cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "dev-eks-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true
                  before_compute = true}
  }

  eks_managed_node_groups = {
    dev_nodes = {
      capacity_type  = "SPOT"
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1

      labels = {
        Environment = "dev"
        Capacity    = "spot"
        test = "ci-verified2"
      }
    }
  }
}

# module "karpenter" {
#   source       = "../../modules/karpenter"
#   cluster_name = module.eks.cluster_name
#   subnet_ids   = module.vpc.private_subnets
# }

# output "eks_cluster_endpoint" {
#   value = module.eks.cluster_endpoint
# }
