# Creating all the components for the  aws loab balancer
# First we need to create an assume policy data resource
# Then we need to create an iam role and attach the assume policy document
# Then we create an iam policy for the aws load balancer controller that defines the actual permissions in AWS.
# This policy will use a josn file
# Then we attach th epolicy to the IAM role that will be used by the controller
# Then we link the IAM role with the kubernetes service account and specify the specific namespace where the aws lbc will be deployed
# Finally we use helm to deploy teh AWS loadbalncer controller



# Creating the assume policy as a data resource that will attach to the role
data "aws_iam_policy_document" "aws_lbc" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["pods.eks.amazonaws.com"]
        }

        actions = [
            "sts:AssumeRole",
            "sts:TagSession"
        ]
    }
  
}

# Creating the role and attaching the assume policy to it
resource "aws_iam_role" "aws_lbc" {
    name = "${aws_eks_cluster.eks.name}-aws-lbc"
    assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
  
}

# Creating the iam plicy for the loadbalancer controller that defines actual permissions in AWS
resource "aws_iam_policy" "aws_lbc" {
    policy = file("./iam/AWSLoadBalancerController.json")
    name = "AWSLoadBalancerController"
  
}


# Attaching the policy to the IAM role that will be used by the controller
resource "aws_iam_role_policy_attachment" "aws_lbc" {
    policy_arn = aws_iam_policy.aws_lbc.arn
    role = aws_iam_role.aws_lbc.name
  
}


# Linking the iam role with the service account and specifying the namespace where the load balancer will be deployed
resource "aws_eks_pod_identity_association" "aws_lbc" {
    cluster_name = aws_eks_cluster.eks.name
    namespace = "kube-system"
    service_account = "aws-load-balancer-controller"
    role_arn = aws_iam_role.aws_lbc.arn
  
}

# Using helm to deploy the AWS load balancer controller
resource "helm_release" "aws_lbc" {
    name = "aws-load-balancer-controller"

    repository = "https://aws.github.io/eks-charts"
    chart = "aws-load-balancer-controller"
    namespace = "kube-system"
    version = "1.7.2"

    set = [
        {
            name = "clusterName"
            value = aws_eks_cluster.eks.name
        },
        {
            name = "region"
            value = "us-west-2"
        },
        {
            name = "vpcId"
            value = aws_vpc.main_vpc.id
        },
        {
            name = "serviceAccount.name"
            value = "aws-load-balancer-controller"
        }
    ]

    depends_on = [
        helm_release.cluster_autoscaler,
        aws_iam_role_policy_attachment.aws_lbc,
        aws_eks_pod_identity_association.aws_lbc

     ]
  
}