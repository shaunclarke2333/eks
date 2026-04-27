# IAM role for the worker nodes
resource "aws_iam_role" "nodes" {
  name = "${var.tagging}-${var.eks_name}-eks-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]

  })

}

# Attaching the required policies to the worker nodes role
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


# This policy allows the cluster to manaage network interfaces on our behalf, which is necessary for
# the pods and worker nodes to communicate with the EKS cluster and other AWS services.
resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# This allows the worker nodes to pull container images from Amazon our private ECR
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# Creating the EKS node group. This is managed as a EC2 autoscaling behind the scenes
resource "aws_eks_node_group" "name" {
  # Using teh cluster name to attach the node group to the cluster we created in the previous step
  cluster_name = aws_eks_cluster.eks.name
  # Using the same version as the cluster to ensure compatibility between the control plane and worker nodes
  version         = var.eks_version
  node_group_name = "general-purpose-node-group"
  # Attaching the IAM role we created for the worker nodes to the node group
  # so that the worker nodes can assume this role and have the necessary permissions to interact with AWS services.
  node_role_arn = aws_iam_role.nodes.arn

  # Specifying the subnets where the worker nodes will be lauched.
  # We are using the private subnets for better security
  # ensuring that the worker nodes are not directly exposed to the internet.
  subnet_ids = [
    aws_subnet.private_zone1.id,
    aws_subnet.private_zone2.id
  ]

  # Specifying the type of nodes to be used for the node group.
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  # Spefifying the minimum and max number of nodes for scaling
  # This does not scale by itself, we also need to deploy the cluster autoscaler in the EKS cluster to enable automatic scaling of the worker nodes based on the workload demands.
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 0
  }

  # This block is used to specify how the node group should be updated when there are changes to the configuration.
  # So at any given time, only one node will be unavailable during the update process
  # which helps to maintain the availability of the applications running on the cluster.
  update_config {
    max_unavailable = 1
  }

  # Adding labels to the node group to help with scheduling and organization of the worker nodes within the EKS cluster.
  labels = {
    "environment" = "practice"
    "role"        = "worker"
  }

  #Explicitly specifying the dependency on the iam role attachments to ensure that the policies are attached to the role before the node group tries to use it.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only
  ]

  # Allowign external changes withut terraform plan diffrences.
  # This is useful for updates that are made outside of Terraform
  # such as changes to the node group configuration or scaling settings.
  # Whem the desired size of the node group is updated outside of Terraform by the auto scaler, this block will prevent Terraform from trying to revert the change back to the original desired size during the next plan or apply.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Name = "${var.tagging}-${var.eks_name}-eks-nodes"
  }

}
