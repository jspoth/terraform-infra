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