output "aws_subnet_id" {
  value = aws_subnet.pubsub1.id
}

output "aws_route_table_route" {
  value = aws_route_table.main_rt.route
}

output "aws_security_group" {
  value = aws_security_group.allow_inbound_outbound.name
}

output "main_vpc_id" {
  value = aws_vpc.main.id
}

output "other_vpc_id" {
  value = aws_vpc.other.id
}