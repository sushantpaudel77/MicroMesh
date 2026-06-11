variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tables" {
  description = "DynamoDB tables configuration"
  type = map(object({
    name          = string
    hash_key      = string
    hash_key_type = string
    billing_mode  = optional(string, "PAY_PER_REQUEST")
    gsis = optional(map(object({
      name           = string
      hash_key       = string
      hash_key_type  = string
    })), {})
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}