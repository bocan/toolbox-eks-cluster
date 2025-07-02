variable "vpc_id" {
  description = "The ID of the VPC where the resources will be created. Only required if `create_vpc` is set to false."
  type        = string
}
