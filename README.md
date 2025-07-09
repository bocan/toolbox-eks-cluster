# toolbox-eks-cluster

[![Pre-commit Checks](https://img.shields.io/badge/pre--commit-enabled-brightgreen)](https://pre-commit.com/)
[![Terraform](https://img.shields.io/badge/terraform--docs-automated-blueviolet)](https://terraform-docs.io/)

A simple tool to quickly provision and manage a cost-effective Amazon EKS (Elastic Kubernetes Service) cluster on AWS, designed for rapid prototyping, dev/test environments, and learning Kubernetes on the cloud. This is NOT mean for production use!

It has 2 _modes_. It can either create a dedicated VPC and put the EKS cluster into it, or it can use an existing VPC.

To a normal Terraform user, you'll find this tool a little strange because:

* It avoids public modules almost entirely in favour of pure resources. (There's 1 public module for VPC endpoints, but I'll be removing that soon.)  This is frankly because I've found all the big public modules to be too inflexible for my needs, and too prone to breaking changes.
* It avoids being too parameterized.  Let's just call it opinionated. Again, this tool isn't meant for flexibility, it's meant for simplicity and ease of use.

**THIS DOCUMENT IS A WORK IN PROGRESS. IT IS NOT COMPLETE AND MAY CHANGE SIGNIFICANTLY.**

---

## Features

- **One-command EKS Cluster Creation:** Spin up an EKS cluster with sane defaults.
- **Cost-focused:** Uses minimal resources and SPOT instances to keep AWS charges low.
- **Customizable:** Easy to tweak for your needs.
- **OpenTofu / Terraform based:** Infrastructure as Code using [OpenTofu](https://opentofu.org/) or [Terraform](https://www.terraform.io/).
- **Pre-commit hooks:** Ensures code quality, formatting, and updates to documentation via [terraform-docs](https://terraform-docs.io/).

---

## Requirements

- [OpenTofu](https://opentofu.org/docs/intro/install/) or [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for interacting with the cluster)
- [pre-commit](https://pre-commit.com/) (for local checks)

---

## Costings

If this thing is run solidly for 1 month, it will cost a minimum of $206. That's **before** any Karpenter nodes are added. I'd make a conservative guess that it could maybe double that once you start adding pods in anger.  But all that said, this is designed to be run for a few **hours** at a time, not 24/7. Turn it on, play with it, then turn it off. If you do that, you can expect it to cost between 3 and 6 dollers per day - assuming 8 hours of usage per day.

---

## Getting Started - using OpenTofu

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
tofu init
```

### 4. Review and set variables

Copy `terraform.tfvars.example` to `terraform.tfvars`, edit the variables as needed (see [Inputs](#inputs) below).

### 5. Create your EKS cluster

```bash
tofu apply
```

### 6. (Optional) Destroy your EKS cluster

```bash
tofu destroy
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.2.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.2 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.2.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 3.0.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.19.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |
| <a name="module_vpclookup"></a> [vpclookup](#module\_vpclookup) | ./modules/vpclookup | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.pod_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.karpenter_irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.karpenter_irsa_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.karpenter_node_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.karpenter_irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.nodes_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.eks_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.aws_auth](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_setup_ec2nodeclass](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_setup_nodepool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.eks_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.nodes_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | The architecture to use for the EKS cluster | `string` | `"arm64"` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | CIDR block for the VPC - if we are creating a new VPC | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Whether to create a new VPC or use an existing one | `bool` | `true` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of the project | `string` | `"eks-lab"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources in | `string` | n/a | yes |
| <a name="input_shortname"></a> [shortname](#input\_shortname) | Your name - shortened | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the existing VPC to use - if we are not creating a new VPC | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

---

## Security

- Follows AWS and Kubernetes security best practices where possible.
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
