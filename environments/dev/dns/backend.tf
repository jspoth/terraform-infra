terraform {
  backend "s3" {
    bucket         = "jsp-test-tfstate"
    key            = "dev/dns.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
