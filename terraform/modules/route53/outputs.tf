output "zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Route53 Name Servers"
  value       = data.aws_route53_zone.main.name_servers
}

output "root_domain" {
  description = "Root domain FQDN"
  value       = aws_route53_record.root.fqdn
}

output "www_domain" {
  description = "WWW domain FQDN"
  value       = aws_route53_record.www.fqdn
}