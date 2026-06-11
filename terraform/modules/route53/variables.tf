variable "domain_name" {
  description = "Root domain name (e.g., cloudforsushant.xyz)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2 for CloudFront)"
  type        = string
  default     = "Z2FDTNDATAQYW2"  # CloudFront's hosted zone ID (same for everyone)
}

variable "create_dev_record" {
  description = "Create dev subdomain record"
  type        = bool
  default     = false
}

variable "create_cert_validation" {
  description = "Create DNS validation records for ACM"
  type        = bool
  default     = false
}

variable "cert_validation_options" {
  description = "ACM certificate validation options"
  type = list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_value = string
    resource_record_type  = string
  }))
  default = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}