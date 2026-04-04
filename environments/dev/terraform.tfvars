region     = "us-east-2"
cidr_block = "10.0.0.0/16"

public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

azs = [
  "us-east-2b",
  "us-east-2a",
]

vpc_name = "dev-vpc"

# environment = "dev"

#added 3/4/2026 since lb
public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
}

