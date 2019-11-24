resource "aws_lambda_function" "auth_lambda" {
  s3_bucket     = "${local.lambda_artefacts_s3_bucket}"
  s3_key        = "${local.artefacts_s3_key}"
  function_name = "${local.service_name}-auth-lambda-${var.aws_region}"
  handler       = "dist/handlers/Authorizer.handler"
  runtime       = "nodejs8.10"
  role          = "${aws_iam_role.auth_lambda_role.arn}"
  memory_size   = 512
  timeout       = 15

  environment {
    variables = {
      JWKS_URI       = "https://xxxx.xx.xxxxx.xxx/.xxxx-xxxxx/xxxx.json"
      AUDIENCE       = "audience"
      TOKEN_ISSUER   = "https://xxxx.xx.xxxxx.xxx/"
      TEST_CLIENT_ID = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group_auth_lambda" {
  name              = "/aws/lambda/${local.service_name}-auth-lambda-${var.aws_region}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "auth_lambda_logging_policy_document" {
  version = "2012-10-17"

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "auth_lambda_logging_policy" {
  name        = "${local.service_name}-auth-lambda-${var.aws_region}"
  path        = "/"
  description = "IAM policy for logging from the auth lambda for ${local.service_name}"

  policy = "${data.aws_iam_policy_document.auth_lambda_logging_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "auth_lambda_logging_role_policy_attachment" {
  role       = "${aws_iam_role.auth_lambda_role.name}"
  policy_arn = "${aws_iam_policy.auth_lambda_logging_policy.arn}"
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "${local.service_name}-authorizer-${var.aws_region}"
  rest_api_id            = "${aws_api_gateway_rest_api.updates_api.id}"
  authorizer_uri         = "${aws_lambda_function.auth_lambda.invoke_arn}"
  authorizer_credentials = "${aws_iam_role.role_for_authorizer_invocation.arn}"
}

resource "aws_iam_role" "role_for_authorizer_invocation" {
  name = "api_gateway_auth_lambda_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy_for_authorier_invocation" {
  name = "default"
  role = "${aws_iam_role.role_for_authorizer_invocation.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.auth_lambda.arn}"
    }
  ]
}
EOF
}