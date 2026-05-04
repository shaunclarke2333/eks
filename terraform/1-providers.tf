provider "aws" {
  region = var.region
}

terraform {
  # Terraform version requirement
  required_version = "~> 1.15.0"

  # Required providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42.0"
    }
  }
}

