### iam module
### Creates the EKS cluster service role and the worker node role/instance
### profile needed to stand up the cluster in Phase 4.
###
### The OIDC provider resource below is gated behind var.oidc_issuer_url.
### It stays uncreated until Phase 4 supplies the cluster's real issuer URL -
### at that point this same module call just gets new inputs, no rewrite.
### IRSA roles (cluster-autoscaler, ALB controller, EBS CSI driver) are NOT
### created here - each needs a workload-specific trust policy and is added
### when that controller is actually deployed (Phases 5/8).

# ---------------------------------------------------------------------------
# EKS cluster role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_role" {
  name               = "${var.project_name}-${var.environment}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam:aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam:aws:policy/AmazonEKSVVPCResourceController"
}

# ---------------------------------------------------------------------------
# Node (worker) role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_role" {
  name               = "${var.project_name}-${var.environment}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam:aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam:aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam:aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM (not SSH) for break-glass node access - no inbound port 22 needed anywhere.
resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam:aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "node_instanceprof" {
  name = "${var.project_name}-${var.environment}-eks-node-profile"
  role = aws_iam_role.node_role.name

  tags = var.tags
}

# ---------------------------------------------------------------------------
# OIDC provider for IRSA - created only once oidc_issuer_url is supplied
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "open_id" {
  count = var.oidc_issuer_url != null ? 1 : 0

  url             = var.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]

  tags = var.tags
}
