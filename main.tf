###########################
# Minimal EKS w/ Karpenter
# No bloated modules, clean resources
###########################

locals {
  project_name = "eks-lab"
  shortname    = "chrisfu"
  region       = "eu-west-1"
  cidr_block   = "10.3.0.0/16"
  common_tags = {
    Environment = "Temporary Lab: ${local.project_id}"
    ManagedBy   = "Terraform"
    Note        = "This is a temporary lab environment being used for testing / experimentation"
    Owner       = "Chris Funderburg"
  }
  project_id = "${local.project_name}-${local.shortname}"

  create_vpc = false
  vpc_id     = "vpc-0a1b2c3d4e5f6g7h8" # Replace with your existing VPC ID
}

module "vpc" {
  count  = local.create_vpc ? 1 : 0
  source = "./modules/vpc"

  cidr_block  = local.cidr_block
  common_tags = local.common_tags
  project_id  = local.project_id
}

module "vpclookup" {
  count  = local.create_vpc ? 0 : 1
  source = "./modules/vpclookup"

  vpc_id      = local.vpc_id
  #cidr_block  = local.cidr_block
}
