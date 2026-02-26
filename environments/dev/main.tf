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