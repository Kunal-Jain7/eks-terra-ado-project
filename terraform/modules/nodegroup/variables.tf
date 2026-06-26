### modules/nodegroup/variables.tf
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster this node group belongs to"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/qa/prod)"
}

variable "node_group_name_suffix" {
  type        = string
  description = "Suffix appended to <cluster_name> to form the node group name. Use a short descriptor like 'general' or 'spot'."
  default     = "general"
}

variable "node_role_arn" {
  type        = string
  description = "ARN of the IAM role for the worker nodes (from modules/iam)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs to place worker nodes in (from modules/network)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the worker nodes"
  default     = "c7i-flex.large"
}

variable "ami_type" {
  type        = string
  description = "AMI type for the node group. AL2023_x86_64_STANDARD is the current recommended default"
  default     = "AL2023_x86_64_STANDARD"
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT. Use ON_DEMAND for production reliability."
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "spot"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  type        = number
  default     = 2
  description = "Initial desired number of worker nodes"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of worker nodes (used by Cluster Autoscaler)"
}

variable "max_size" {
  type        = number
  default     = 4
  description = "Maximum number of worker nodes (used by Cluster Autoscaler and upgrade surge"
}

variable "max_unavailable_percentage" {
  type        = number
  description = "Maximum percentage of nodes that can be unavailable during a rolling node group upgrade. 34% = 1 of 2 nodes at a time."
  default     = 34

  validation {
    condition     = var.max_unavailable_percentage >= 1 && var.max_unavailable_percentage <= 100
    error_message = "max_unavailable_percentage must be between 1 and 100."
  }
}

variable "node_disk_size_gb" {
  type        = number
  description = "Root EBS volume size in GB for each worker node"
  default     = 50
}

variable "ebs_kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt node EBS volumes (from modules/security)"
}

variable "node_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  description = "Kubernetes taints to apply to nodes in this group. Useful for dedicated node groups"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}

variable "node_labels" {
  type        = map(string)
  default     = {}
  description = "Additional Kubernetes node labels to apply to all nodes in this group"
}
