variable "vpc_name" {
  type = string
}
variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}
variable "public_subnets" {
  type = list(string)
}
variable "azs" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}
variable "public_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "private_subnet_tags" {
  type    = map(string)
  default = {}
}