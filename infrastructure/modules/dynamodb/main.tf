terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DynamoDB Table - SmartGrowData
# Single-table design with PK/SK pattern
resource "aws_dynamodb_table" "smart_grow_data" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  hash_key       = "PK"
  range_key      = "SK"

  # Primary Key attributes
  attribute {
    name = "PK"
    type = "S"  # String - e.g., "PLOT#12", "USER#123", "FACILITY#1"
  }

  attribute {
    name = "SK"
    type = "S"  # String - e.g., "STATE#2025-10-28T12:00:00Z", "SENSOR#temp"
  }

  # GSI attributes (Global Secondary Index)
  attribute {
    name = "GSI_PK"
    type = "S"  # String - Alternative partition key (e.g., SpeciesId, FacilityId)
  }

  attribute {
    name = "GSI_SK"
    type = "S"  # String - Alternative sort key (e.g., Timestamp, PlotId)
  }

  # Global Secondary Index for alternative queries
  global_secondary_index {
    name            = var.gsi_name
    hash_key        = "GSI_PK"
    range_key       = "GSI_SK"
    projection_type = "ALL"  # Include all attributes in the index
  }

  # Enable Point-in-Time Recovery for data protection
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # TTL configuration (optional - can be used to auto-delete old records)
  dynamic "ttl" {
    for_each = var.ttl_attribute != "" ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.table_name
    }
  )
}

