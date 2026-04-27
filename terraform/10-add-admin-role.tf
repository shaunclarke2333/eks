# Creating this data resource to retrieve the current account id to use in the trust relationship of the iam role to allow the user to assume the role.
data "aws_caller_identity" "eks_admin_current" {}

# Creatig am iam group for cluster administrators
resource "aws_iam_group" "eks_admin_group" {
  name = "${var.tagging}-eks-admin-group"

}

# Creating an aws user for the cluster administrator
resource "aws_iam_user" "eks_admin_user" {
  name = "eks-admin"

}

# Adding the user to the group
resource "aws_iam_user_group_membership" "eks_admin_user_group_membership" {
  user = aws_iam_user.eks_admin_user.name
  groups = [
    aws_iam_group.eks_admin_group.name
  ]
}



# Creating an IAM role for cluster administrator
# The user gets permission to assume this role through IAM group membership.
resource "aws_iam_role" "eks_admin_role" {
  name = "${var.tagging}_eks_admin_role"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.eks_admin_current.account_id}:root"
          }
        }
      ]
    }
  )

}

# Creating an IAM policy that will be attached to the group to allows the role assumption
resource "aws_iam_policy" "allow_assume_eks_admin_role" {
  name = "${var.tagging}_allow_assume_eks_admin_role"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sts:AssumeRole"
          Resource = aws_iam_role.eks_admin_role.arn
        }
      ]
    }
  )

}

# Attachinf the assume role policy to the group
resource "aws_iam_group_policy_attachment" "allow_assume_eks_admin_role" {
  group      = aws_iam_group.eks_admin_group.name
  policy_arn = aws_iam_policy.allow_assume_eks_admin_role.arn
}


# This aim policy gives full access to the EKS cluster.
# Creating an IAM policy that will be attached to the role to allow full access to the cluster
resource "aws_iam_policy" "eks_admin_policy" {
  name = "${var.tagging}_eks_admin_policy"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "eks:*"
          ]
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "iam:PassRole"
          Resource = "*"
          "Condition" : {
            "StringEquals" : {
              "iam:PassedToService" : "eks.amazonaws.com"
            }
          }
        }
      ]
    }
  )

}

# Attaching the AWS EKS admin policy to the group
resource "aws_iam_group_policy_attachment" "eks_admin_group_policy_attachment" {
  group      = aws_iam_group.eks_admin_group.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}


# attaching the AWS EKS admin policy to the role
resource "aws_iam_role_policy_attachment" "eks_admin_role_policy_attachment" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}

# Binding the role to a group in kubernetes that has admin permissions.
# This allows the user to assume the role and have admin permissions on the cluster.
# A role is used because an iam group cannot be directly mapped to a kubernetes group in the aws-auth configmap.
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.eks_admin_role.arn
  type              = "STANDARD"
  kubernetes_groups = ["my-admin"]

}