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
}
