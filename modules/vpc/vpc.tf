resource "aws_vpc" "this" {
  cidr_block                       = var.cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags                             = merge(var.common_tags, { Name = "${var.project_id}-vpc" })
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.project_id}-igw" })
}

resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:We want a public subnet. This isn't for produciton. Just testing / demo / development purposes
  count                           = 3
  vpc_id                          = aws_vpc.this.id
  cidr_block                      = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(var.common_tags, { Name = "${var.project_id}-public-${count.index}" })
}


resource "aws_subnet" "private" {
  count                           = 3
  vpc_id                          = aws_vpc.this.id
  cidr_block                      = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + 10)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index + 10)
  assign_ipv6_address_on_creation = true
  availability_zone               = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(var.common_tags, { Name = "${var.project_id}-private-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.common_tags, { Name = "${var.project_id}-nat" })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.project_id}-eip" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.common_tags, { Name = "${var.project_id}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.common_tags, { Name = "${var.project_id}-private-rt" })
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ------------------------
# CloudWatch & Flow Logs
# ------------------------
resource "aws_iam_role" "flow_logs" {
  name = "${var.project_id}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, { Name = "${var.project_id}-flow-logs-role" })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_id}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_logs.arn}:*"
      }
    ]
  })
}

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for encrypting CloudWatch Log Groups"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "AllowRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowAllIAMUsersInAccountToUseKey"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name              = "/aws/vpc/${var.project_id}-flow-logs"
  retention_in_days = 365
  tags              = merge(var.common_tags, { Name = "${var.project_id}-flow-logs" })
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_flow_log" "vpc" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  iam_role_arn         = aws_iam_role.flow_logs.arn
}
