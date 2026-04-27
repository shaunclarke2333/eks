# Creating  a static public IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.tagging}-nat"
  }
}

# Creating the NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  # The NAT Gateway must be created in a public subnet, so we reference the public subnet created in the previous step
  subnet_id = aws_subnet.public_zone1.id

  tags = {
    Name = "${var.tagging}-nat"
  }

  # Explixitly use the "depends_on" argument to ensure that the NAT Gateway is created after the public subnet, igw and the Elastic IP
  depends_on = [aws_internet_gateway.igw, aws_subnet.public_zone1, aws_eip.nat]

}

