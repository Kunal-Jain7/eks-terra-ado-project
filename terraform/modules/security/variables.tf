variable "project_name" {
  type        = string
  description = "Project name used in the resources and the tags"
}

variable "environment" {
  type        = string
  description = "Environment Name {Dev, QA, Prod}"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID these security groups are created in."
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the ingress load balancer {from the network module}"
  default     = ["0.0.0.0/0"]
}

variable "admin_access_cidrs" {
  type        = list(string)
  description = "Trusted CIDRs granted extra HTTPS access to the EKS API server via the additional cluster SG. Leave empty to skip"
  default     = []
}

variable "cluster_security_group_id" {
  type        = string
  description = "EKS cluster's auto-created security group ID. Leave null until the EKS cluster exists."
  default     = null
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional resources tags"
}
