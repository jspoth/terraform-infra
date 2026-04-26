variable "cidr_block" {}
variable "public_subnets" {
  type = list(string)
}
variable "azs" {
  type = list(string)
}
variable "vpc_name" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "addons" {
  type    = map(any)
  default = {}
}

variable "public_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "private_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "region" {
  type        = string
  description = "AWS region"
}