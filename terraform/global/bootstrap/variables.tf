variable "aws_region" {
  type        = string
  description = "The region where all the resources will be deployed"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name used to derive the state bucket and lock table names"
  default     = "eksplat"
}

variable "tags" {
  type = map(string)
  default = {
    Owner      = "platform-team"
    CostCenter = "eng-platform"
  }
}
