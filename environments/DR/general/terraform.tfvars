region     = "us-west-2"
cidr_block = "10.1.0.0/16"

public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets = ["10.1.101.0/24", "10.1.102.0/24"]

azs = [
  "us-west-2b",
  "us-west-2a",
]

vpc_name = "dr-vpc"

# environment = "dr"

#added 3/4/2026 since lb
public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "karpenter.sh/discovery"          = "dr-eks-cluster"
}

