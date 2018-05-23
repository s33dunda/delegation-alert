data "terraform_remote_state" "centralpark" {
  backend   = "s3"
  workspace = "${terraform.workspace}"

  config {
    bucket = "2u-terraform"
    key    = "centralpark"
    region = "us-east-1"
  }
}
