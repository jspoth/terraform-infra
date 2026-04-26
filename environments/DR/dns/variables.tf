variable "region" {
  type    = string
  default = "us-west-2"
}

variable "domain" {
  type        = string
  description = "Root domain name for the Route 53 hosted zone"
  default     = "jspoth.com"
}

variable "cluster_name" {
  type    = string
  default = "dr-eks-cluster"
}

variable "ingress_name" {
  type    = string
  default = "go-app-ingress"
}

variable "dns_records" {
  type        = list(string)
  description = "List of DNS names to point at the ALB (e.g. apex as empty string or full FQDNs)"
  default     = ["app.jspoth.com"]
}
