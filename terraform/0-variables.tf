variable "tagging" {
  description = "A prefix for tagging AWS resources"
  type        = string
}


variable "env" {
  description = "The environment for the EKS cluster (e.g., staging, production)"
  type        = string
}

variable "region" {
  description = "The AWS region where the EKS cluster will be created"
  type        = string
}

variable "zones" {
  description = "The availability zones for the EKS cluster"
  type        = list(string)
}

variable "eks_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
}

variable "main_vpc_cidr" {
  description = "The CIDR block for the main VPC"
  type        = string
}
