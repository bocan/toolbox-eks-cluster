variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "eks-lab"
}
variable "shortname" {
  type        = string
  description = "Your name - shortened"
}
variable "region" {
  type        = string
  description = "AWS region to deploy resources in"
}
variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC - if we are creating a new VPC"
}
variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}
variable "vpc_id" {
  type        = string
  description = "The ID of the existing VPC to use - if we are not creating a new VPC"
}
variable "create_vpc" {
  type        = bool
  description = "Whether to create a new VPC or use an existing one"
  default     = true
}
variable "architecture" {
  type        = string
  description = "The architecture to use for the EKS cluster"
  default     = "arm64"
}
