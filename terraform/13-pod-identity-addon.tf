# Deploying eks pod identity agents as an add on. The addon is deployed as a daemon set so it runs on every single node in the cluster
# The Pod identity addon helps give the nodes permissions to communicate with AWS to scale the cluster up and down.

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.3"

}