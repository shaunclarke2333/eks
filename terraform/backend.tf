# Remote state backend configuration for Terraform
terraform {
  backend "s3" {
    bucket = "eks-journey-terraform-state"
    key    = "eks-journey/terraform.tfstate"
    region = "us-west-2"

    # Enabling native S3 state locking
    use_lockfile = true
  }
}