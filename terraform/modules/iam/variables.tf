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

variable "oidc_issuer_url" {
  type        = string
  description = "EKS Cluster OIDS issuer URL"
  default     = null
}

variable "oidc_thumbprint" {
  type        = string
  description = "SHA1 thumbprint of the OIDC issuer's TLS Certificate. Required when oidc_issuer is set"
  default     = null
}
