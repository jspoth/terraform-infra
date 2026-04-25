module "vpc" {
  source = "../../../modules/vpc"

  vpc_name            = var.vpc_name
  cidr_block          = var.cidr_block
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  azs                 = var.azs
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name = "dev-eks-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  addons = {
    coredns                = { most_recent = true, before_compute = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true, before_compute = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    dev_nodes = {
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "SPOT"
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1

      labels = {
        Environment = "dev"
        Capacity    = "spot"
        test        = "ci-verified2"
      }
    }
  }
}

module "aws_load_balancer_controller" {
  source = "../../../modules/aws-load-balancer-controller"

  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  region            = var.region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider
}

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::831714862044:role/github-actions-terraform"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::831714862044:role/github-actions-terraform"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
