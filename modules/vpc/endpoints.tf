module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Stupid Check
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.19.0"

  vpc_id = aws_vpc.this.id

  endpoints = { for service in toset(["ssm", "ssmmessages", "ec2messages"]) :
    replace(service, ".", "_") =>
    {
      service             = service
      subnet_ids          = aws_subnet.private[*].id
      private_dns_enabled = true
      tags                = { Name = "${var.project_id}-${service}" }
    }
  }

  create_security_group      = true
  security_group_name_prefix = "${var.project_id}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from subnets"
      cidr_blocks = [aws_vpc.this.cidr_block]
    }
  }

  tags = var.common_tags

}
