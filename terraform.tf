terraform {
  backend "s3" {
    encrypt = "true"
    bucket  = "2u-terraform"
    key     = "delegation-alert-lambda"
    region  = "us-east-1"
  }

  lock_table = "terraform-locks"
}
