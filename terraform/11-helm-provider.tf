# Creating data resource to retrieve the cluster name
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

# Creating a data resource to get teh name of the cluster authentication 
data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name

}

# Resource block that initilizes helm
provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}