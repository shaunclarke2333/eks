# The idea here is:
# create a user
# create a group
# add the user to the group
# create a role with a trust relationship that allows the user to assume the role
# create a policy that allows the user to assume the role 
# attach the assume role policy to the group
# create an AWS side policy that allows the user to discover and connect to the EKS cluster
# attach the AWS side policy to the group and the role
# Bind the role that can be assumed by the user to a group in kubernetes that RBAC permissions to the cluster.
# This allows the user to connect to the cluster and be permitted to do whatever the permissions on that group in kubernetes is allowed to do.

# Configuring the AWS CLI for the user to be able to assume the role and connect to the cluster is outside the scope of this terraform code, but it can be done by running the following command in the terminal:
# aws configure set role_arn arn:aws:iam::<account_id>:role/<role_name> --profile <profile_name>
# Then the user can use the profile to connect to the cluster using kubectl by running:
# aws eks update-kubeconfig --name <cluster_name> --region <region> --profile <profile_name>
# Step 1: Configure base IAM user credentials (one-time setup)
# aws configure --profile developer

# Step 2: Add role-based profile (edit AWS config file)
# Open config file:
# nano ~/.aws/config
#
# Add the following:
# [profile eks-developer]
# role_arn = arn:aws:iam::<account-id>:role/<eks-developer-role-name>
# source_profile = developer
# region = us-west-2

# Step 3: Verify role assumption (should return assumed-role ARN)
# aws sts get-caller-identity --profile eks-developer

# Step 4: Configure kubeconfig to use the assumed role
# aws eks update-kubeconfig \
#   --region us-west-2 \
#   --name <cluster-name> \
#   --profile eks-developer


# Data source for caller identity to get the current account id. This is used in the trust relationship of the iam role to allow the user to assume the role. 
data "aws_caller_identity" "current" {}

# Creating an IAM group for developers
resource "aws_iam_group" "developer" {
  name = "${var.tagging}-developer"

}

# Creating an aws user for the developer
resource "aws_iam_user" "developer" {
  name = "developer"

}

# Adding the user to the group
resource "aws_iam_user_group_membership" "developer" {
  user = aws_iam_user.developer.name
  groups = [
    aws_iam_group.developer.name
  ]
}


# The user gets permission to assume this role through IAM group membership.
resource "aws_iam_role" "eks_developer_role" {
  name = "${var.tagging}_eks_developer_role"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
        }
      ]
    }
  )

}



# Creating an IAM policy that will be attached to the group to allows the role assumption
resource "aws_iam_policy" "allow_assume_eks_role" {
  name = "${var.tagging}_allow_assume_eks_role"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sts:AssumeRole"
          Resource = aws_iam_role.eks_developer_role.arn
        }
      ]
    }
  )

}

# Attaching the assume role policy to the group
resource "aws_iam_group_policy_attachment" "allow_assume_eks_role" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.allow_assume_eks_role.arn
}


# policy to allow AWS side permissions. Allows user to discover and connect to the EKS cluster
resource "aws_iam_policy" "developer_eks" {
  name        = "${var.tagging}AmazonEKSDeveloperPolicy"
  path        = "/"
  description = "Policy to allow developer basic access to EKS cluster. Enough to update their kubeconfig and conect to the cluster. Does not allow any access to the cluster itself."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

}

# Attaching the AWS side policy to the iam group
resource "aws_iam_group_policy_attachment" "developer_eks" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.developer_eks.arn
}

# Attaching the AWS side policy to the iam role as well
resource "aws_iam_role_policy_attachment" "developer_eks" {
  role       = aws_iam_role.eks_developer_role.name
  policy_arn = aws_iam_policy.developer_eks.arn
}


# Binding the developer role to clusteer role in kubernetes.
# A role is used because an iam group cannot be binded to a group in kubernetes
resource "aws_eks_access_entry" "developer" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.eks_developer_role.arn
  type              = "STANDARD"
  kubernetes_groups = ["viewer-group"]

}

