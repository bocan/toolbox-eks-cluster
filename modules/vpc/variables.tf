variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
variable "project_id" {
  description = "Project ID for the resources"
  type        = string
}
