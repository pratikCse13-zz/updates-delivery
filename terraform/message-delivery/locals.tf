locals {
  service_name = "message-delivery"

  artefacts_s3_key = "${var.repo}/${var.version}.zip"

  lambda_artefacts_s3_bucket = "lambda-artefacts-${var.aws_region}"

  updates_history_table_name = "updates_history"
}
