variable "region" {
  type    = string
  default = "us-east-2"
}

variable "domain" {
  type        = string
  description = "Root domain name for the Route 53 hosted zone"
  default     = "jspoth.com"
}

variable "cluster_name" {
  type    = string
  default = "dev-eks-cluster"
}

variable "ingress_name" {
  type    = string
  default = "go-app-ingress"
}

variable "github_pages_ips" {
  type        = list(string)
  description = "GitHub Pages IPs for the apex domain"
  default     = ["185.199.108.153", "185.199.109.153", "185.199.110.153", "185.199.111.153"]
}

variable "dns_records" {
  type        = list(string)
  description = "List of DNS names to point at the ALB (e.g. apex as empty string or full FQDNs)"
  default     = ["app.jspoth.com"]
}

variable "healthcheck_domain" {
  type        = string
  description = "Domain for Route 53 health check"
  default     = "app.jspoth.com"
}
