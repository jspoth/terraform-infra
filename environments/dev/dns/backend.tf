terraform {
  backend "s3" {
    bucket         = "jsp-test-tfstate"
    key            = "dev/dns.tfstate"
    region         = "us-east-2"
    use_lockfile   = true
    encrypt        = true
  }
}
