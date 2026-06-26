### modules/monitoring/variables.tf

variable "project_name" {
  type        = string
  description = "Project name used in resource naming and tags"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/qa/prod)"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name — used to name log groups and scope metric dimensions"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN from modules/eks — required to create the CloudWatch agent IRSA role"
}

variable "oidc_provider_url" {
  type        = string
  description = "OIDC provider URL without https:// — used in the IRSA trust policy StringEquals condition"
}

variable "cloudwatch_addon_version" {
  type        = string
  description = "Version of the amazon-cloudwatch-observability EKS addon. Set to null to use the EKS default for the cluster's K8s version."
  default     = null
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log group retention in days"
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400,
      545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "log_retention_days must be one of the values AWS CloudWatch supports."
  }
}

variable "alarm_email" {
  type        = string
  description = "Email address to send CloudWatch alarm notifications to. Set to null to skip email subscription."
  default     = null
}

variable "alarm_period_seconds" {
  type        = number
  description = "Period in seconds over which to evaluate each alarm metric"
  default     = 300
}

variable "alarm_evaluation_periods" {
  type        = number
  description = "Number of consecutive periods that must breach the threshold to trigger an alarm"
  default     = 2
}

variable "cpu_alarm_threshold" {
  type        = number
  description = "Node CPU utilization percentage that triggers an alarm"
  default     = 80
}

variable "memory_alarm_threshold" {
  type        = number
  description = "Node memory utilization percentage that triggers an alarm"
  default     = 80
}

variable "filesystem_alarm_threshold" {
  type        = number
  description = "Node filesystem utilization percentage that triggers an alarm"
  default     = 85
}

variable "pod_restart_threshold" {
  type        = number
  description = "Total pod restart count within one alarm period that triggers an alarm"
  default     = 5
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}
