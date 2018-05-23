data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./index.js"
  output_path = "index.zip"
}

provider "vault" {}

variable "delegation_alert_function_name" {
  default = "delegation_alert"
}

variable "environment" {
  type = "map"

  default = {
    prod.vault_path          = "secret/implementation/centralpark/delegation_alert"
    prod.centralpark_domain  = "centralpark.2u.com"

    dev.vault_path          = "secret/implementation/centralpark/delegation-alert"
    dev.centralpark_domain  = "dev.centralpark.2u.com"
  }
}

resource "aws_lambda_function" "centralpark_delegation_alert" {
  function_name = "${var.delegation_alert_function_name}_${terraform.workspace}"
  description   = "alerts centralpark when dns was delegated"

  filename         = "index.zip"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs6.10"
  memory_size      = "512"
  role             = "${module.lambda_insert_role.arn}"
  handler          = "index.forward_delegation_alert"
  timeout          = 300

  environment {
    variables = {
      "ENVIRONMENT"= "${terraform.workspace}"
      "CP_API_KEY" = "${data.vault_generic_secret.api_token.data["api_key"]}"
      "CP_DOMAIN"  = "${lookup(var.environment, "${terraform.workspace}.centralpark_domain")}"
    }
  }
}
