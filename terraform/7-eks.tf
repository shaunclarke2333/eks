# creating iam role that the eks cluster will assume
resource "aws_iam_role" "eks" {
  name = "${var.tagging}-${var.eks_name}-eks-cluster"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        }
      ]
    }
  )

  tags = (
    {
      "Name" = "${var.tagging}-${var.eks_name}-eks-cluster"
    }
  )
}

# attaching the required policies to the role
resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

# Creating the EKS cluster
resource "aws_eks_cluster" "eks" {
  name    = "${var.tagging}-${var.eks_name}-eks-cluster"
  version = var.eks_version
  # This is the IAM role that the EKS cluster will assume to create and manage resources on our behalf.
  role_arn = aws_iam_role.eks.arn

  # This is where we specify the subnets that the EKS cluster will use.
  # We are using the private subnets we created earlier because we want to launch our worker nodes in private subnets for better security.
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id
    ]
  }

  # This block is used to specify how the cluster should authenticate with the Kubernetes API server.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Explicitly specifying the dependency on the iam role to ensure that the role is created before the cluster tries to use it.
  depends_on = [aws_iam_role_policy_attachment.eks]



}