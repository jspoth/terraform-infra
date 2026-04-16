terraform {
  backend "s3" {
    bucket         = "jsp-test-tfstate"      # replace with your bucket
    key            = "dev/addons.tfstate" # path inside bucket
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}