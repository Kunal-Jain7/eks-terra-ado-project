variable "project_name" {
  type        = string
  description = "Project name used in the resources and the tags"
}

variable "environment" {
  type        = string
  description = "Environment Name {Dev, QA, Prod}"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional resources tags"
}
