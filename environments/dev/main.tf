provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source = "../../modules/vpc"

  name           = "dev-vpc"
  cidr_block     = var.cidr_block
  public_subnets = var.public_subnets
  azs            = var.azs
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = "dev-eks-cluster"
  vpc_id          = "vpc-0301e2afaf3bafbb0"
  subnet_ids      = ["subnet-03dedde9362f3bd1a"]
  node_group_name = "dev-nodes"
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}