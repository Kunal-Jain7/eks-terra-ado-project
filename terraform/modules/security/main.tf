### security module
### Creates the security groups EKS worker nodes and the ingress load
### balancer need, plus the KMS keys used for EKS secrets envelope
### encryption and EBS volume encryption.
###
### The control-plane <-> node SG rules are gated behind
### var.cluster_security_group_id, which stays null until the EKS module
### exists (Phase 4) and exposes the cluster's auto-created SG ID.

# ---------------------------------------------------------------------------
# Worker node security group
# ---------------------------------------------------------------------------

resource "aws_security_group" "eks_sg" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS managed worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-nodes-sg"
  })
}

resource "aws_security_group_rule" "nodes_self_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_sg.id
  source_security_group_id = aws_security_group.eks_sg.id
  description              = "Node to node / Pod to pod communication"
}

resource "aws_security_group_rule" "nodes_self_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_sg.id
  description       = "Unrestricted egress (Image Pulls, API calls, DNS via NAT )"
}

# Gated: created once cluster_security_group_id is supplied (Phase 4)
resource "aws_security_group_rule" "nodes_ingress_https_from_cluster" {
  count = var.cluster_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_sg.id
  source_security_group_id = var.cluster_security_group_id
  description              = "Control plane to node HTTPS"
}

resource "aws_security_group_rule" "nodes_ingress_kubelet_from_cluster" {
  count = var.cluster_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_sg.id
  source_security_group_id = var.cluster_security_group_id
  description              = "Control Plane to kubelet"
}

# ---------------------------------------------------------------------------
# ALB / ingress load balancer security group
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the application/ingress load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from allowed CIDRs"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS allowed from CIDRs"
}

resource "aws_security_group_rule" "alb_egress_to_nodes" {
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_sg.id
  description              = "ALB to node / pod target ports"
}

resource "aws_security_group_rule" "nodes_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_sg.id
  source_security_group_id = aws_security_group.alb.id
  description              = "ALB to nodeport / pod target pods"
}

# ---------------------------------------------------------------------------
# Optional supplementary SG on the EKS cluster API server (trusted admin CIDRs)
# ---------------------------------------------------------------------------

resource "aws_security_group" "cluster_additional" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-additional-sg"
  vpc_id      = var.vpc_id
  description = "Optional supplementary SG attached to the eks cluster API server"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-additional-sg"
  })
}

resource "aws_security_group_rule" "cluster_additional_admin_ingress" {
  for_each = toset(var.admin_access_cidrs)

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.cluster_additional.id
  description       = "trusted admin access to the EKS API server"
}

# ---------------------------------------------------------------------------
# KMS keys
# ---------------------------------------------------------------------------
resource "aws_kms_key" "eks_secrets" {
  deletion_window_in_days = 30
  enable_key_rotation     = true
  description             = "EKS secrets envelop encryption key"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-secrets-kms"
  })
}

resource "aws_kms_alias" "eks_alias" {
  name          = "alias/${var.project_name}-${var.environment}-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

resource "aws_kms_key" "ebs" {
  description             = "EBS volume encryption key for eks worker nodes"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ebs-kms"
  })
}

resource "aws_kms_alias" "ebs_alias" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}
