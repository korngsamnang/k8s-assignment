resource "aws_route_table_association" "name" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.rt_custom_internal.id
}