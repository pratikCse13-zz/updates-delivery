#--------------------------------------------------------------
# Api Gateway
#--------------------------------------------------------------
resource "aws_api_gateway_rest_api" "updates_api" {
  name        = "Message-Delivery"
  description = "API Gateway used for updates"

  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }
}

resource "aws_api_gateway_deployment" "updates_api_deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.updates_api.id}"
  stage_name  = "${var.environment}"

  depends_on = [
    "aws_api_gateway_rest_api.updates_api",
    "aws_api_gateway_integration.get_lambda_integration",
    "aws_api_gateway_integration.post_lambda_integration"
  ]

  variables {
    build_number = "${var.build_number}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "updates_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.updates_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.updates_api.root_resource_id}"
  path_part   = "sendupdate"
}

resource "aws_api_gateway_method_settings" "api-gateway_method_setting" {
  rest_api_id = "${aws_api_gateway_rest_api.updates_api.id}"
  stage_name  = "${var.environment}"
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "INFO"
  }

  depends_on = [
    "aws_api_gateway_rest_api.updates_api",
    "aws_api_gateway_resource.updates_api_resource"
  ]
}

# resource "aws_api_gateway_method_settings" "proxy_settings" {
#   rest_api_id = "${aws_api_gateway_rest_api.api.id}"
#   stage_name  = "${aws_api_gateway_deployment.proxy_api.stage_name}"
#   method_path = "*/*"

#   settings {
#     logging_level = "${local.log_level}"
#   }
# }
