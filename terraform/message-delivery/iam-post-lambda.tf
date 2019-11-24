data "aws_iam_policy_document" "post_lambda_role_assume_policy_document" {
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

resource "aws_iam_role" "post_lambda_role" {
  name               = "${local.service_name}-post-lambda-role-${var.aws_region}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.post_lambda_role_assume_policy_document.json}"
}

data "aws_iam_policy_document" "ses_sending_policy_for_lambda" {
  statement = [
    {
      actions = [
        "ses:SendRawEmail",
        "ses:SendEmail",
      ]

      effect = "Allow"

      resources = ["*"] // There is only one shared SES resource setup by SRE
    },
  ]
}

resource "aws_iam_policy" "ses_sending_policy" {
  name        = "${local.service_name}-post-lamnda-ses-access-policy"
  description = "Allows sending HTML and raw email with SES"
  policy      = "${data.aws_iam_policy_document.ses_sending_policy_for_lambda.json}"
}

resource "aws_iam_role_policy_attachment" "ses_sending_policy_attachment" {
  role       = "${aws_iam_role.post_lambda_role.name}"
  policy_arn = "${aws_iam_policy.ses_sending_policy.arn}"
  depends_on = ["aws_iam_role.post_lambda_role"]
}

data "aws_iam_policy_document" "post_lambda_db_access_policy_document" {
  statement = [
    {
      actions = [
        "dynamodb:PutItem"
      ]

      effect = "Allow"

      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_profile}:table/${local.updates_history_table_name}",
      ]
    }
  ]
}

resource "aws_iam_policy" "post_lambda_db_access_policy" {
  name        = "${local.service_name}-post-lambda-db-access-policy"
  description = "Allows access to DynamoDB Write"
  policy      = "${data.aws_iam_policy_document.post_lambda_db_access_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "db_write_policy_attachment" {
  role       = "${aws_iam_role.post_lambda_role.name}"
  policy_arn = "${aws_iam_policy.post_lambda_db_access_policy.arn}"
  depends_on = ["aws_iam_role.post_lambda_role"]
}