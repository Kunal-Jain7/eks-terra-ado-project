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

data "aws_caller_identity" "current" {}

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

  # Explicit key policy: grants root full access (required baseline) PLUS
  # the AWS Auto Scaling service-linked role permission to use this key.
  # The EKS managed node group's underlying ASG launches EC2 instances with
  # encrypted EBS volumes on your behalf — without this grant, instance
  # creation fails with "KMS key is inaccessible" and the node group hangs.

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowAutoScalingServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowAutoScalingServiceLinkedRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2ServiceUseOfTheKey"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
        ]
        Resource = "*"
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ebs-kms"
  })
}

resource "aws_kms_alias" "ebs_alias" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

resource "aws_kms_grant" "ebs_autoscaling" {
  name              = "${var.project_name}-${var.environment}-ebs-asg-grant"
  key_id            = aws_kms_key.ebs.key_id
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

  operations = [
    "Decrypt",
    "DescribeKey",
    "CreateGrant",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "ReEncryptFrom",
    "ReEncryptTo",
  ]
}
