output "endpoint_ids" {
  description = "All endpoint IDs"
  value = {
    gateway   = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
    interface = { for k, v in aws_vpc_endpoint.interface : k => v.id }
  }
}