variable "project_name" {
  type        = string
  description = "Project Name, Used to derive default bucket/table names and tags"
}

variable "bucket_name" {
  type        = string
  description = "Override for the state bucket-name. Defaults to <project-name>-terraform_state-<account-id>"
  default     = null
}

variable "table_name" {
  type        = string
  description = "Override for the DynamoDB lock table name. Defaults to <project_name>-terraform-locks"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Additional Resource tags"
  default     = {}
}
