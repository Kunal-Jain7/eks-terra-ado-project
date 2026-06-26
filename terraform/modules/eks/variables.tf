### modules/eks/variables.tf

variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Initially pinned to older version to exercise the upgrade the path later of the kubernetes version"
  default     = "1.30"
}

variable "cluster_role_arn" {
  type        = string
  description = "ARN of the IAM role for the EKS cluster control plane"
}

# Used by depends_on to ensure IAM role policies are attached before cluster creation
variable "cluster_role_policy_dependency" {
  type        = any
  description = "Pass module.iam here so terraform waits for IAM policy attachments before creating the cluster"
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet ID's the control plane ENIs and worker nodes are placed in"
}

variable "node_security_group_id" {
  type        = string
  description = "Security group ID of the worker nodes. Used to create the cross-SG control plane rules"
}

variable "cluster_additional_security_group_id" {
  type        = string
  description = "Additional security group ID attached to the cluster API server"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used for EKS secrets envelope encryption"
}

variable "endpoint_public_access" {
  type        = bool
  default     = true
  description = "Whether the EKS API server endpoint is publicly accessible. Set to false for prod hardening."
}

variable "public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the public EKS API endpoint. Only used when endpoint_public_access = true."
}

variable "addon_versions" {
  type        = map(string)
  description = <<-EOT
    Pinned versions for the four core EKS managed addons.
    Use null for any entry to let EKS select the default version for the
    cluster's Kubernetes version (acceptable for dev; pin explicitly for prod).
    Check available versions with:
      aws eks describe-addon-versions --kubernetes-version 1.30 --addon-name <name>
  EOT
  default = {
    "vpc-cni"            = null
    "coredns"            = null
    "kube-proxy"         = null
    "aws-ebs-csi-driver" = null
  }
}

variable "ebs_csi_irsa_role_arn" {
  type        = string
  default     = null
  description = "IRSA role ARN for the EBS CSI driver service account. Leave null to skip (driver will use node role instead, which is acceptable for dev)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional resource tags"
}
