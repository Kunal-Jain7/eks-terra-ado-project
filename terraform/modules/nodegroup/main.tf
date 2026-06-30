### modules/nodegroup/main.tf
###
### Creates:
###  - An EC2 launch template that enforces KMS-encrypted EBS root volumes
###    and sets the IMDSv2-only requirement (security hardening).
###  - An EKS managed node group that references the launch template.
###
### The update_config block controls the rolling upgrade behaviour used in
### Phase 10. max_unavailable_percentage = 34 means at most ~1 node out of
### the default 2 is replaced at once, keeping the other available throughout
### the upgrade. This value is exposed as a variable so it can be tuned
### without changing the module code.

locals {
  node_group_name = "${var.cluster_name}-${var.node_group_name_suffix}"
}

# ---------------------------------------------------------------------------
# Launch template
# ---------------------------------------------------------------------------

resource "aws_launch_template" "eks_nodes" {
  name        = "${local.node_group_name}-lt"
  description = "Launch template for EKS managed node group ${local.node_group_name}"

  # Enforce IMDSv2 (hop limit 1 = pods cannot reach the metadata service
  # directly, they must go via the node; set to 2 if running containers that
  # legitimately need instance metadata)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # KMS-encrypted root volume
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.node_group_name}-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${local.node_group_name}-ebs"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Managed node group
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "eks_nodegroup" {
  cluster_name    = var.cluster_name
  node_group_name = local.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  # Reference the launch template above for EBS encryption + IMDSv2.
  # instance_types is set here (not in the launch template) because
  # EKS managed node groups require it on the resource, not the template,
  # when using a custom launch template without an AMI ID.

  instance_types = [var.instance_type]

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  # Controls the rolling upgrade behaviour during a node group version update.
  # max_unavailable_percentage = 34% means ~1 of 2 nodes is replaced at a time,
  # ensuring at least 1 node is always available during an upgrade.
  # In Phase 10 we will lower this further and combine it with PodDisruptionBudgets.

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # EKS AMI type - AL2023 is the current recommended Amazon Linux variant
  ami_type = var.ami_type

  # Use ON_DEMAND for reliability; SPOT can be enabled for dev/qa cost savings
  capacity_type = var.capacity_type

  labels = merge(var.node_labels, {
    "role"        = "worker"
    "environment" = var.environment
  })

  dynamic "taint" {
    for_each = var.node_taints
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  tags = merge(var.tags, {
    Name = local.node_group_name
  })

  lifecycle {
    # Ignore desired_size changes after creation so external autoscalers
    # (Cluster Autoscaler / Karpenter) can freely adjust the count without
    # Terraform reverting it on the next apply.
    ignore_changes        = [scaling_config[0].desired_size]
    create_before_destroy = true
  }
}
