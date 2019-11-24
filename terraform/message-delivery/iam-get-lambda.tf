data "aws_iam_policy_document" "get_lambda_role_assume_policy_document" {
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

resource "aws_iam_role" "get_lambda_role" {
  name               = "${local.service_name}-get-lambda-role-${var.aws_region}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.get_lambda_role_assume_policy_document.json}"
}

data "aws_iam_policy_document" "get_lambda_db_access_policy_document" {
  statement = [
    {
      actions = [
        "dynamodb:Query"
      ]

      effect = "Allow"

      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_profile}:table/${local.updates_history_table_name}",
      ]
    }
  ]
}

resource "aws_iam_policy" "get_lambda_db_access_policy" {
  name        = "${local.service_name}-get-lambd-db-access-policy"
  description = "Allows access to DynamoDB Read"
  policy      = "${data.aws_iam_policy_document.get_lambda_db_access_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "db_read_policy_attachment" {
  role       = "${aws_iam_role.get_lambda_role.name}"
  policy_arn = "${aws_iam_policy.get_lambda_db_access_policy.arn}"
  depends_on = ["aws_iam_role.get_lambda_role"]
}