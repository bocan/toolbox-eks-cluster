#####################################
# Minimal EKS w/ Karpenter
# No bloated modules, clean resources
#####################################

locals {
  project_name = var.project_name
  shortname    = var.shortname
  region       = var.region
  cidr_block   = var.cidr_block
  common_tags  = var.common_tags

  project_id = "${local.project_name}-${local.shortname}"

  create_vpc = var.create_vpc
  vpc_id     = var.vpc_id
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

  vpc_id = local.vpc_id
  #cidr_block  = local.cidr_block
}
