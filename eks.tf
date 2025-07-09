# ------------------------
# KMS for Encryption
# ------------------------
resource "aws_kms_key" "eks" {
  description         = "EKS encryption key"
  enable_key_rotation = true
  tags                = merge(local.common_tags, { Name = "${local.project_id}-kms" })
}

# ------------------------
# EKS Cluster
# ------------------------
resource "aws_eks_cluster" "this" {
  name     = "${local.project_id}-eks"
  role_arn = aws_iam_role.eks.arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = local.create_vpc ? module.vpc[0].private_subnet_ids : module.vpclookup[0].private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(local.common_tags, { Name = local.project_id })
}

# ------------------------
# EKS IAM Roles
# ------------------------
resource "aws_iam_role" "eks" {
  name               = "${local.project_id}-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = merge(local.common_tags, { Name = "${local.project_id}-role" })
}


resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------
# EKS Addons
# ------------------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = merge(local.common_tags, { Name = "${local.project_id}-vpc-cni" })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = merge(local.common_tags, { Name = "${local.project_id}-kube-proxy" })
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = merge(local.common_tags, { Name = "${local.project_id}-coredns" })
  depends_on                  = [aws_eks_node_group.managed, aws_eks_addon.vpc_cni, aws_eks_addon.kube_proxy]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = merge(local.common_tags, { Name = "${local.project_id}-pod-identity" })
}

# ---------------------------
# LAUNCH TEMPLATE FOR NODE GROUP
# ---------------------------
resource "aws_launch_template" "eks_managed" {
  name_prefix   = "${local.project_id}-eks-ng-"
  image_id      = null # Let EKS manage the AMI unless you have a custom one
  instance_type = "${local.machine_type}.medium"

  metadata_options {
    http_tokens = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.project_id}-eks-ng" })
  }
}

# ------------------------
# Managed Node Group
# ------------------------
resource "aws_eks_node_group" "managed" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.project_id}-managed"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = local.create_vpc ? module.vpc[0].private_subnet_ids : module.vpclookup[0].private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  launch_template {
    id      = aws_launch_template.eks_managed.id
    version = "$Latest"
  }

  ami_type      = var.architecture == "arm64" ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
  capacity_type = "SPOT"

  tags = merge(local.common_tags, { Name = "${local.project_id}-managed-nodes" })

  labels = {
    "karpenter.sh/controller" = "true"
  }
}

# ------------------------
# Node IAM Role
# ------------------------
resource "aws_iam_role" "nodes" {
  name               = "${local.project_id}-nodes-role"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume.json
  tags               = merge(local.common_tags, { Name = "${local.project_id}-nodes-role" })
}


resource "aws_iam_role_policy_attachment" "nodes_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

# ------------------------
# OIDC & IRSA for Karpenter
# ------------------------
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10b30"]
  tags            = merge(local.common_tags, { Name = "${local.project_id}-oidc" })
}

resource "aws_iam_role" "karpenter_irsa" {
  name = "${local.project_id}-karpenter-irsa-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
  tags = merge(local.common_tags, { Name = "${local.project_id}-karpenter-irsa-role" })
}

resource "aws_iam_role_policy_attachment" "karpenter_irsa" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.karpenter_irsa.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "karpenter_node_extra" {
  name = "${local.project_id}-karpenter-node-extra"
  role = aws_iam_role.karpenter.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["eks:DescribeCluster", "ec2:Describe*", "ssm:GetParameter"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "karpenter_irsa_extra" {
  name = "${local.project_id}-karpenter-irsa-extra"
  role = aws_iam_role.karpenter_irsa.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "ssm:GetParameter",
          "pricing:GetProducts",
          "iam:GetInstanceProfile",
          "iam:PassRole",
          "eks:DescribeCluster"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "kubectl_manifest" "aws_auth" {
  yaml_body = local.aws_auth
}

# ------------------------
# Karpenter Setup
# ------------------------
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  namespace        = "karpenter"
  create_namespace = true

  values = [templatefile("${path.module}/karpenter_values.yaml", {
    cluster_name     = aws_eks_cluster.this.name
    cluster_endpoint = aws_eks_cluster.this.endpoint
    instance_profile = aws_iam_instance_profile.karpenter.name
    role_arn         = aws_iam_role.karpenter_irsa.arn
  })]
  depends_on = [
    kubectl_manifest.aws_auth
  ]
}

resource "aws_iam_role" "karpenter" {
  name = "${local.project_id}-karpenter-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = merge(local.common_tags, { Name = "${local.project_id}-karpenter-role" })
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.karpenter.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "${local.project_id}-karpenter"
  role = aws_iam_role.karpenter.name
}

resource "kubectl_manifest" "karpenter_setup_ec2nodeclass" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: al2023@latest
  instanceProfile: "${local.project_id}-karpenter"
  subnetSelectorTerms:
    - tags:
        Name: "${local.project_id}-private-0"
    - tags:
        Name: "${local.project_id}-private-1"
    - tags:
        Name: "${local.project_id}-private-2"
  securityGroupSelectorTerms:
    - tags:
        "kubernetes.io/cluster/${aws_eks_cluster.this.name}": owned
  tags:
    karpenter.sh/discovery: "${aws_eks_cluster.this.name}"
YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_setup_nodepool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: ["${local.machine_type}.small", "${local.machine_type}.medium", "${local.machine_type}.large"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["${var.architecture}"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
YAML

  depends_on = [helm_release.karpenter]
}
