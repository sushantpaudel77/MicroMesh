resource "aws_dynamodb_table" "main" {
  for_each = var.tables

  name         = each.value.name
  billing_mode = each.value.billing_mode
  hash_key     = each.value.hash_key

  # Primary key attribute
  attribute {
    name = each.value.hash_key
    type = each.value.hash_key_type
  }

  # GSI key attributes - one attribute block per unique GSI key
  dynamic "attribute" {
    for_each = {
      for k, v in each.value.gsis : k => v
      if v.hash_key != each.value.hash_key
    }
    content {
      name = attribute.value.hash_key
      type = attribute.value.hash_key_type
    }
  }

  # Global Secondary Indexes — use key_schema block (provider v6, replaces deprecated hash_key arg)
  dynamic "global_secondary_index" {
    for_each = each.value.gsis
    content {
      name            = global_secondary_index.value.name
      projection_type = "ALL"

      key_schema {
        attribute_name = global_secondary_index.value.hash_key
        key_type       = "HASH"
      }
    }
  }

  point_in_time_recovery {
    enabled = var.environment == "prod"
  }

  tags = var.tags
}
