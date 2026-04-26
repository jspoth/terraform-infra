terraform {
  backend "s3" {
    bucket       = "jsp-test-tfstate-dr"
    key          = "dr/messaging/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
