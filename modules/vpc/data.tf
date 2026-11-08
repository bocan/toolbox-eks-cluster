# ------------------------
# Data Sources
# ------------------------

data "aws_availability_zones" "available" {
  # checkov:skip=CKV_AWS_394: Region-agnostic module. Subnets only use the first 3 AZs, so a newly added AZ does not change the result.
}

data "aws_caller_identity" "current" {}
