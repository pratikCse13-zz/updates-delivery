data "aws_iam_policy_document" "auth_lambda_role_assume_policy_document" {
  version = "2012-10-17"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    effect = "Allow"
    sid    = ""
  }
}

resource "aws_iam_role" "auth_lambda_role" {
  name               = "${local.service_name}-auth-lambda-role-${var.aws_region}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.auth_lambda_role_assume_policy_document.json}"
}