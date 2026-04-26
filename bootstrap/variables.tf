variable "aws_region" {
  default = "us-east-2"
}

variable "dr_region" {
  default = "us-west-2"
}

variable "tfstate_bucket_dr" {
  default = "jsp-test-tfstate-dr"
}

variable "github_org" {
  description = "GitHub organization or username"
}

variable "github_repo" {
  description = "Repository name(s) to allow GitHub Actions OIDC access"
  type        = list(string)
}