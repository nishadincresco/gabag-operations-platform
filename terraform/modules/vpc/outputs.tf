output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "eic_endpoint_sg_id" {
  value = aws_security_group.eic_endpoint.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}
