output "vpc_id" {
  value = aws_vpc.client_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.client_vpc.cidr_block
}

output "internet_gateway_id" {
  value = aws_internet_gateway.client_ig.id
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public_subnet : s.id]
  description = "List of public subnets ID's"
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private_subnet : s.id]
}

output "public_subnet_ids_by_az" {
  value = { for az, s in aws_subnet.public_subnet : az => s.id }
}

output "private_subnet_ids_by_az" {
  value = { for az, s in aws_subnet_private_subnet : az => s.id }
}

output "nat_gateway_ids" {
  value = [for n in aws_nat_gateway.client_nat : n.id]
}

output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}

output "private_route_table_ids" {
  value = { for k, rt in aws_route_table.private-rt : k => rt.id }
}

output "availability_zones" {
  value = var.availability_zones
}
