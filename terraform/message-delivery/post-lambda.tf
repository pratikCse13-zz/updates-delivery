resource "aws_lambda_function" "post_lambda" {
  s3_bucket     = "${local.lambda_artefacts_s3_bucket}"
  s3_key        = "${local.artefacts_s3_key}"
  function_name = "${local.service_name}-post-lambda-${var.aws_region}"
  handler       = "dist/handlers/PostUpdates.handler"
  runtime       = "nodejs8.10"
  role          = "${aws_iam_role.post_lambda_role.arn}"
  memory_size   = 512
  timeout       = 15

  environment {
    variables = {
      EMAIL_SENDER_ADDRESS       = "${var.email_sender_address}"
      UPDATES_HISTORY_TABLE_NAME = "${local.updates_history_table_name}"
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group_post_lambda" {
  name              = "/aws/lambda/${local.service_name}-post-lambda-${var.aws_region}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "post_lambda_logging_policy_document" {
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

resource "aws_iam_policy" "post_lambda_logging_policy" {
  name        = "${local.service_name}-post-lambda-${var.aws_region}"
  path        = "/"
  description = "IAM policy for logging from the post lambda for ${local.service_name}"

  policy = "${data.aws_iam_policy_document.post_lambda_logging_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "post_lambda_logging_role_policy_attachment" {
  role       = "${aws_iam_role.post_lambda_role.name}"
  policy_arn = "${aws_iam_policy.post_lambda_logging_policy.arn}"
}

resource "aws_api_gateway_integration" "post_lambda_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.updates_api.id}"
  resource_id             = "${aws_api_gateway_resource.updates_api_resource.id}"
  http_method             = "${aws_api_gateway_method.post_api_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.post_lambda.invoke_arn}"

  depends_on = [
    "aws_api_gateway_rest_api.updates_api",
  ]
}

resource "aws_api_gateway_method" "post_api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.updates_api.id}"
  resource_id   = "${aws_api_gateway_resource.updates_api_resource.id}"
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = "${aws_api_gateway_authorizer.authorizer.id}"

  depends_on = [
    "aws_api_gateway_rest_api.updates_api",
    "aws_api_gateway_resource.updates_api_resource"
  ]
}

resource "aws_api_gateway_method_response" "post_api_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.updates_api.id}"
  resource_id = "${aws_api_gateway_resource.updates_api_resource.id}"
  http_method = "${aws_api_gateway_method.post_api_method.http_method}"
  status_code = "200"
}

# Lambda
resource "aws_lambda_permission" "post_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.post_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"
}