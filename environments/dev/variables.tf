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