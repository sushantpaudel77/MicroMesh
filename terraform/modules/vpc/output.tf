output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [for k, v in aws_subnet.main : v.id if var.subnets[k].tier == "public"]
}

output "ecs_subnet_ids" {
  description = "ECS subnet IDs"
  value       = [for k, v in aws_subnet.main : v.id if var.subnets[k].type == "ecs"]
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = [for k, v in aws_subnet.main : v.id if var.subnets[k].type == "database"]
}

output "ecs_route_table_id" {
  description = "ECS route table ID"
  value       = aws_route_table.main["private"].id
}

output "all_subnet_ids" {
  description = "All subnet IDs mapped by key"
  value       = { for k, v in aws_subnet.main : k => v.id }
}