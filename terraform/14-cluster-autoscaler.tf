# Creating all the components for the cluster autoscaler
# First we need a role with the trust relationsip "pos.eks.amazon.com"
# Then we need to create a policy that allows the EKS cluster to access the AWS autoscaling group
# Then we attach the policy to the iam role
# Then we associate the role with the a kubernetes  service account
# Then we use the Helm provider to deploy the cluster_autoscaler to the eks cluster

# Creating the role with trust relationship that will give the cluster autoscaler permission to AWS autoscaling group
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole",
            "sts:TagSession"
          ]
          Principal = {
            Service = "pods.eks.amazonaws.com"
          }
        }
      ]
    }
  )
}

# Creating the policy to attach to the role that allows the cluster autoscaler to access the AWS autoscaling group.
resource "aws_iam_policy" "cluster_auto_scaler" {
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeScalingActivities",
            "autoscaling:DescribeTags",
            "ec2:DescribeImages",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:GetInstanceTypesFromInstanceRequirements",
            "eks:DescribeNodegroup"
          ]
          Resource = "*"

        },
        {
          Effect = "Allow"
          Action = [
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup"
          ]
          Resource = "*"

        },
      ]
    }
  )
}

# Attach the policy to the IAM for the autoscaler
resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
    policy_arn = aws_iam_policy.cluster_auto_scaler.arn
    role = aws_iam_role.cluster_autoscaler.name
}

# Associating the AWS role to a kubernetes service account and providing the specific namespace autoscaler will be running in.
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
    cluster_name = aws_eks_cluster.eks.name
    namespace = "kube-system"
    service_account = "cluster-autoscaler"
    role_arn = aws_iam_role.cluster_autoscaler.arn
  
}

# Using the helm provider to deploy the cluster autoscaler
resource "helm_release" "cluster_autoscaler" {
    name = "autoscaler"
    repository = "https://kubernetes.github.io/autoscaler"
    chart = "cluster-autoscaler"
    namespace = "kube-system"
    version = "9.37.0"

    set = [
        
        {
            name =  "rbac.serviceAccount.name"
            value = "cluster-autoscaler"
        },
        {
            name = "autoDiscovery.clusterName"
            value = aws_eks_cluster.eks.name
        },
        {
            name = "awsRegion"
            value = "us-west-2"
        }

    ]

    depends_on = [ helm_release.metrics_server ]

}