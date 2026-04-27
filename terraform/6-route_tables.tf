# Creating route tables for both private and public subnets to manage traffic routing within the VPC.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    # Default route that will be used if no other routes match.
    #This is necessary for the private subnets to access the internet via the NAT Gateway.
    cidr_block = "0.0.0.0/0"
    # Referencing the NAT Gateway created in the previous step to route traffic from private subnets to the internet.
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.tagging}-private-rt"
  }

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    # Default route that will be used if no other routes match.
    # This is necessary for the public subnets to access the internet directly via the Internet Gateway.
    cidr_block = "0.0.0.0/0"
    # Referencing the Internet Gateway created in the previous step to route traffic from public subnets to the internet.
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.tagging}-public-rt"
  }

}

# Associating the private route table with the private subnets to ensure that traffic
# from these subnets is routed through the NAT Gateway.
resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_zone1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_zone2.id
  route_table_id = aws_route_table.private.id
}

# Associating the public route table with the public subnets to ensure that traffic
# from these subnets is routed through the Internet Gateway.
resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_zone1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_zone2" {
  subnet_id      = aws_subnet.public_zone2.id
  route_table_id = aws_route_table.public.id
}
