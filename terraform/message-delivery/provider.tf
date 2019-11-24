provider "aws" {
  region              = "eu-central-1"
  profile             = "${var.aws_profile}"
  allowed_account_ids = ["${var.aws_profile}"]
}