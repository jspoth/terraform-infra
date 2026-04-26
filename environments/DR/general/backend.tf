terraform {
  backend "s3" {
    bucket         = "jsp-test-tfstate-dr"      # replace with your bucket
    key            = "dr/general/terraform.tfstate"
    region         = "us-west-2"
    use_lockfile   = true
    encrypt        = true
  }
}