### modules/eks/main.tf
###
### Creates the EKS control plane, the OIDC provider for IRSA, the
### cross-SG rules that allow the control plane to reach kubelet/HTTPS on
### the worker nodes, and the four core managed addons (vpc-cni, coredns,
### kube-proxy, aws-ebs-csi-driver).
###
### Cross-SG rules live here (not in modules/security) to avoid a circular
### dependency: this module already holds the auto-created cluster SG ID
### and receives the node SG ID as an input, so it is the natural place to
### create the inter-SG rules without needing a second apply pass.

# ---------------------------------------------------------------------------
# EKS cluster
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "client_eks_cluster" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_additional_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }
  # Envelope-encrypt Kubernetes secrets using the customer-managed KMS key
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn
    }
  }
  # Ship all available control-plane log types to CloudWatch.
  # The log group itself is created in modules/monitoring (Phase 5).
  # EKS will auto-create it if it doesn't exist yet; monitoring adds
  # retention/encryption on top.
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  tags = var.tags

  # Ensure IAM role policies propagate before creating the cluster
  depends_on = [var.cluster_role_policy_dependency]
}

# ---------------------------------------------------------------------------
# OIDC provider (lives here, not in modules/iam, to avoid a cycle)
# ---------------------------------------------------------------------------
data "tls_certificate" "cluster_cert" {
  url = aws_eks_cluster.client_eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "open_id" {
  url             = aws_eks_cluster.client_eks_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_cert.certificates[0].sha1_fingerprint]

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Cross-SG rules: control plane <-> worker nodes
# (Both SG IDs are known here, avoiding a circular dep with security module)
# ---------------------------------------------------------------------------
resource "aws_security_group_rule" "cluster_to_node_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Control Plane to node https"
  security_group_id        = var.node_security_group_id
  source_security_group_id = aws_eks_cluster.client_eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "cluster_to_node_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  description              = "Control Plane to Kubelet"
  security_group_id        = var.node_security_group_id
  source_security_group_id = aws_eks_cluster.client_eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "node_to_cluster_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Node to cluster API server HTTPS"
  security_group_id        = aws_eks_cluster.client_eks_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = var.node_security_group_id
}

# ---------------------------------------------------------------------------
# Core managed addons
# ---------------------------------------------------------------------------

# vpc-cni: AWS VPC CNI plugin (pod networking)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.client_eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_versions["vpc-cni"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

# coredns: in-cluster DNS
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.client_eks_cluster.name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions["coredns"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # coredns needs nodes to schedule onto - nodegroup created in separate
  # module so we use a dependency on vpc-cni being ready first
  depends_on = [aws_eks_addon.vpc_cni]

  tags = var.tags
}

# kube-proxy: service networking / iptables
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.client_eks_cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_versions["kube-proxy"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

# aws-ebs-csi-driver: PersistentVolume support
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.client_eks_cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.addon_versions["aws-ebs-csi-driver"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # The EBS CSI driver uses a service account; its IRSA role ARN can be
  # supplied here once the OIDC provider exists. We emit the OIDC provider
  # ARN as an output so the IRSA role can be created alongside this call.
  service_account_role_arn = var.ebs_csi_irsa_role_arn

  tags = var.tags
}
