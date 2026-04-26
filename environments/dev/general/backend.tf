terraform {
  backend "s3" {
    bucket         = "jsp-test-tfstate"      # replace with your bucket
    key            = "dev/terraform.tfstate" # path inside bucket
    region         = "us-east-2"
    use_lockfile   = true
    encrypt        = true
  }
}