variable "project_name" {
  type        = string
  description = "Project name used in the resources and the tags"
}

variable "environment" {
  type        = string
  description = "Environment Name {Dev, QA, Prod}"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones to deploy subnets into"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs block for the public subnets. Must be the same length and order as availability zones"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs block for the private subnets. Must be the same length and order as availability zones"
}

variable "single_nat_gateway" {
  type        = bool
  description = "If true, deploy a single shared NAT gateway instead of one per AZ"
  default     = false
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster name used for the pre-tag subnets"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional resources tags applied to all resources in this module"
}
