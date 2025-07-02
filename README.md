# toolbox-eks-cluster

[![Pre-commit Checks](https://img.shields.io/badge/pre--commit-enabled-brightgreen)](https://pre-commit.com/)
[![Terraform](https://img.shields.io/badge/terraform--docs-automated-blueviolet)](https://terraform-docs.io/)

A simple tool to quickly provision and manage a cost-effective Amazon EKS (Elastic Kubernetes Service) cluster on AWS, designed for rapid prototyping, dev/test environments, and learning Kubernetes on the cloud. This is NOT mean for production use!

To a normal Terraform user, you'll find this tool a little strange because:

* It avoids modules almost entirely in favour of pure resources. (There's 1 module for VPC endpoints, but I'll be removing that soon.)  This is frankly because I've found all the big public modules to be too inflexible for my needs, and too prone to breaking changes.
* It avoids being too parameterized.  Let's just call it opinionated. Again, this tool isn't meant for flexibility, it's meant for simplicity and ease of use.

**THIS DOCUMENT IS A WORK IN PROGRESS. IT IS NOT COMPLETE AND MAY CHANGE SIGNIFICANTLY.**

---

## Features

- **One-command EKS Cluster Creation:** Spin up an EKS cluster with sane defaults.
- **Cost-focused:** Uses minimal resources and SPOT instances to keep AWS charges low.
- **Customizable:** Easy to tweak for your needs.
- **Terraform-based:** Infrastructure as Code using [Terraform](https://www.terraform.io/).
- **Pre-commit hooks:** Ensures code quality, formatting, and updates to documentation via [terraform-docs](https://terraform-docs.io/).

---

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for interacting with the cluster)
- [pre-commit](https://pre-commit.com/) (for local checks)

---

## Costings

If this thing is run solidly for 1 month, it will cost a minimum of $206. That's **before** any Karpenter nodes are added. I'd make a conservative guess that it could maybe double that once you start adding pods in anger.  But all that said, this is designed to be run for a few **hours** at a time, not 24/7. Turn it on, play with it, then turn it off. If you do that, you can expect it to cost between 3 and 6 dollers per day - assuming 8 hours of usage per day.

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/bocan/toolbox-eks-cluster.git
cd toolbox-eks-cluster
```

### 2. Install pre-commit hooks

```bash
pre-commit install
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review and set variables

Edit `terraform.tfvars` or set variables as needed (see [Inputs](#inputs) below).

### 5. Create your EKS cluster

```bash
terraform apply
```

### 6. (Optional) Destroy your EKS cluster

```bash
terraform destroy
```

---

## Examples

Basic usage:

```hcl
module "eks" {
  source = "github.com/bocan/toolbox-eks-cluster"
  # ...add required variables here
}
```

---

## Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.2 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.37.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.5.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 3.0.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.37.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.5.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | ~> 5.19.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.vpc_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_flow_log.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.karpenter_irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.karpenter_irsa_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.karpenter_node_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.karpenter_irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.nodes_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_setup_ec2nodeclass](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_setup_nodepool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [local_file.karpenter_role_entry](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.eks_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.nodes_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/config_map) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

---

## Security

- Follows AWS and Kubernetes security best practices where possible.
- Uses Kyverno policies for pod security by default (see `manifests/kubernetes/kustomize/components/cluster-core/customizations/kyverno-policies.yaml`).
- Review IAM roles and policies before applying to production environments.

---

## Contributing

Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request.

---

## License

[MIT License](LICENSE)

---

## Maintainer

Chris Funderburg ([@bocan](https://github.com/bocan))
