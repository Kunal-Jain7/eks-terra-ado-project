# ── General ────────────────────────────────────────────────────────────────

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

variable "tags" {
  type    = map(string)
  default = {}
}

# ── Network ─────────────────────────────────────────────────────────────────

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


# ── Security ────────────────────────────────────────────────────────────────
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

# ── EKS cluster ─────────────────────────────────────────────────────────────

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type        = string
  default     = "1.30"
  description = "Kubernetes version. Intentionally older to exercise the upgrade path."
}

variable "endpoint_public_access" {
  type        = bool
  default     = true
  description = "Enable public EKS API endpoint access. Set to false for prod hardening."
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDRs permitted to reach the public EKS API endpoint."
  default     = ["0.0.0.0/0"]
}

variable "addon_versions" {
  type        = map(string)
  description = "Pinned EKS addon versions. Set a value to null to use the EKS-default for the cluster's K8s version."
  default = {
    "vpc-cni"            = null
    "coredns"            = null
    "kube-rpoxy"         = null
    "aws-ebs-csi-driver" = null
  }
}

# ── Node group ───────────────────────────────────────────────────────────────

variable "node_group_name_suffix" {
  type        = string
  description = "Suffix for the node group name"
  default     = "general"
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for worker nodes"
  default     = "c7i-flex.large"
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "node_min_size" {
  type        = number
  default     = 4
  description = "Minimum number of worker nodes"
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes (supports upgrade surge + autoscaling)"
  default     = 4
}

# ── Monitoring ───────────────────────────────────────────────────────────────
variable "log_retention_days" {
  type        = number
  default     = 30
  description = "CloudWatch log retention in days"
}

variable "alarm_email" {
  type        = string
  default     = "kunal70223@gmail.com"
  description = "Email address for CloudWatch alarm SNS notifications. Set to null to skip."
}

variable "cpu_alarm_threshold" {
  type        = number
  description = "Node CPU % threshold for alarm"
  default     = 80
}

variable "memory_alarm_threshold" {
  type        = number
  description = "Node Memory % threshold for alarm"
  default     = 80
}

variable "filesystem_alarm_threshold" {
  type        = number
  description = "Node Filesystem % threshold for alarm"
  default     = 85
}

variable "pod_restart_threshold" {
  type        = number
  default     = 5
  description = "Pod restart count threshold per alarm period"
}


