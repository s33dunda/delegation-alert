data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file  = "index.js"
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

data "vault_generic_secret" "api_token" {
  path = "${lookup(var.environment, "${terraform.workspace}.vault_path")}"
}

resource "aws_lambda_function" "centralpark_delegation_alert" {
  function_name = "${var.delegation_alert_function_name}_${terraform.workspace}"
  description   = "alerts centralpark when dns was delegated"

  filename         = "index.zip"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs6.10"
  memory_size      = "512"
  role             = "${module.lambda_delegation_alert_role.arn}"
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

module "lambda_delegation_alert_role" {
  source                  = "github.com/2uinc/centralpark//aws/modules/centralpark-lambda-role"
  env                     = "${terraform.workspace}"
  role_name               = "${var.delegation_alert_function_name}_${terraform.workspace}"
  lambda_arn              = "${aws_lambda_function.centralpark_delegation_alert.arn}"

}
