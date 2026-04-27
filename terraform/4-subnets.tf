resource "aws_subnet" "private_zone1" {
  vpc_id = aws_vpc.main_vpc.id
  # Take th emain vpc_cidr and split it into smaller subnets and use the first 1
  cidr_block        = cidrsubnet(var.main_vpc_cidr, 4, 0)
  availability_zone = var.zones[0]

  tags = {
    Name = "${var.tagging}-private-${var.zones[0]}"
    # This tag is used by EKS to identify which subnets should be used for internal load balancers.
    "kubernetes.io/role/internal-elb" = "1"
    # This tag essentially tells EKS that this subnet is owned by the cluster and should be used for worker nodes and internal load balancers
    "kubernetes.io/cluster/${var.tagging}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id = aws_vpc.main_vpc.id
  # Take th emain vpc_cidr and split it into smaller subnets and use the second one.
  cidr_block        = cidrsubnet(var.main_vpc_cidr, 4, 1)
  availability_zone = var.zones[1]

  tags = {
    Name = "${var.tagging}-private-${var.zones[1]}"
    # This tag is used by EKS to identify which subnets should be used for internal load balancers.
    "kubernetes.io/role/internal-elb" = "1"
    # This tag essentially tells EKS that this subnet is owned by the cluster and should be used for worker nodes and internal load balancers
    "kubernetes.io/cluster/${var.tagging}-${var.eks_name}" = "owned"
  }

}

resource "aws_subnet" "public_zone1" {
  vpc_id = aws_vpc.main_vpc.id
  # Take th emain vpc_cidr and split it into smaller subnets and take the second 1
  cidr_block        = cidrsubnet(var.main_vpc_cidr, 4, 2)
  availability_zone = var.zones[0]
  # Allows AWS to automatically assign public IPs to instances launched in this subnet
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.tagging}-public-${var.zones[0]}"
    # Eks uses this tag to identify which subnets to create public load balancers
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${var.tagging}-${var.eks_name}" = "owned"
  }

}

resource "aws_subnet" "public_zone2" {
  vpc_id = aws_vpc.main_vpc.id
  # Take th emain vpc_cidr and split it into smaller subnets and take the second 1
  cidr_block        = cidrsubnet(var.main_vpc_cidr, 4, 3)
  availability_zone = var.zones[1]
  # Allows AWS to automatically assign public IPs to instances launched in this subnet
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.tagging}-public-${var.zones[1]}"
    # Eks uses this tag to identify which subnets to create public load balancers
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${var.tagging}-${var.eks_name}" = "owned"
  }

}

