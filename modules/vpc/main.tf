# resource "aws_vpc" "this" {
#   cidr_block = var.cidr_block
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = var.name
#   }
# }

# resource "aws_subnet" "public" {
#   count = length(var.public_subnets)

#   vpc_id     = aws_vpc.this.id
#   cidr_block = var.public_subnets[count.index]
#   map_public_ip_on_launch = true

#   availability_zone = var.azs[count.index]

#   tags = {
#     Name = "${var.name}-public-${count.index}"
#   }
# }

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr_block

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  # enable_vpn_gateway = true 3/4 not needed
  single_nat_gateway = true #3/4

  tags = {
     Name = var.vpc_name
   }

   #3/4
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  #3/4
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}