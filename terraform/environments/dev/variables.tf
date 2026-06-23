variable "project_name" {
  type        = string
  description = "Project name used in the resources and the tags"
}

variable "aws_region" {
  type        = string
  description = "AWS region for this environment"
}

variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR Block for this environment's VPC"
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets, one per AZ, same order as availability_zones"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets, one per AZ, same order as availability_zones"
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "Use a single shared NAT Gateway instead of one per AZ (cost optimization for non-prod)"
}

variable "cluster_name" {
  type = string
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the ingress load balancer on 80/443"
}

variable "admin_access_cidrs" {
  type        = list(string)
  description = "Trusted CIDRs granted extra HTTPS access to the EKS API server. Leave empty to skip."
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
