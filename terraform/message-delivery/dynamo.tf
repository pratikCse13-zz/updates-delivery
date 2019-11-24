resource "aws_dynamodb_table" "message-delivery-history" {
  hash_key         = "recipientemail"
  range_key        = "timestamp"
  name             = "${local.updates_history_table_name}"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "recipientemail"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }
}
