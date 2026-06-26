### modules/monitoring/main.tf
###
### Creates:
###  1. KMS key for CloudWatch log encryption
###  2. CloudWatch log groups for EKS control-plane logs and Container Insights
###  3. IRSA role for the CloudWatch Observability agent (Container Insights)
###  4. EKS managed addon: amazon-cloudwatch-observability
###  5. SNS topic + optional email subscription for alarm notifications
###  6. CloudWatch metric alarms (CPU, memory, node health, pod restarts)
###  7. CloudWatch dashboard for at-a-glance cluster health

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# 1. KMS key for CloudWatch log encryption
# ---------------------------------------------------------------------------
resource "aws_kms_key" "cloudwatch" {
  description             = "CloudWatch Logs encryption key - ${local.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # CloudWatch Logs requires an explicit key policy allowing the CW Logs
  # service principal to use this key for your account + region

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:*"
          }
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cloudwatch-kms"
  })
}


resource "aws_kms_alias" "cloudwatch_alias" {
  name          = "alias/${local.name_prefix}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# ---------------------------------------------------------------------------
# 2. CloudWatch log groups
# ---------------------------------------------------------------------------

# EKS control-plane log group.
# EKS auto-creates this group when cluster logging is enabled (Phase 4).
# Terraform managing it here adds KMS encryption + retention. If Terraform
# shows "already exists" on first apply, import it first:
#   terraform import module.monitoring.aws_cloudwatch_log_group.eks_control_plane \
#     /aws/eks/<cluster_name>/cluster

resource "aws_cloudwatch_log_group" "eks_control_plane_loggroup" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eks-control-plane-logs"
  })
}

# Container Insights log group (performance metrics and container logs)
resource "aws_cloudwatch_log_group" "container_insights" {
  name              = "aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-container-insights-logs"
  })
}

# Application log group (Pods write here via Fluent Bit, deployed in Phase 8)
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "aws/containerinsights/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-application-logs"
  })
}

# ---------------------------------------------------------------------------
# 3. IRSA role for the CloudWatch Observability addon agent
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "cw_agent_assume_role" {
  statement {
    actions = ["sts:AssumeRolewithwebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts:amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_agent_role" {
  name               = "${local.name_prefix}-eks-cw-agent-role"
  assume_role_policy = data.aws_iam_policy_document.cw_agent_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cw_attachment" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ---------------------------------------------------------------------------
# 4. EKS managed addon: amazon-cloudwatch-observability
#    Installs the CloudWatch Agent + Fluent Bit as a DaemonSet. Provides
#    Container Insights metrics and log forwarding out of the box.
# ---------------------------------------------------------------------------
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = var.cloudwatch_addon_version
  service_account_role_arn = aws_iam_role.cloudwatch_agent_role.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.cw_attachment]
}

# ---------------------------------------------------------------------------
# 5. SNS topic + optional email subscription for alarm notifications
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name              = "${local.name_prefix}-eks-alarms"
  kms_master_key_id = aws_kms_key.cloudwatch.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eks-alarms"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email != null ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ---------------------------------------------------------------------------
# 6. CloudWatch alarms
# ---------------------------------------------------------------------------

# --- Node CPU ---
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${local.name_prefix}-node-cpu-high"
  alarm_description   = "Worker node CPU utilisation is above ${var.cpu_alarm_threshold}% for ${var.alarm_evaluation_periods} periods"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterNaame = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

# --- Node memory ---

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  alarm_name          = "${local.name_prefix}-node-memory-high"
  alarm_description   = "Worker node memory utilisation is above ${var.memory_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

# --- Node filesystem ---

resource "aws_cloudwatch_metric_alarm" "node_filesystem_high" {
  alarm_name          = "${local.name_prefix}-node-filesystem-high"
  alarm_description   = "Worker node filesystem utilisation is above ${var.memory_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "node_filesystem_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.filesystem_alarm_threshold

  treat_missing_data = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

# --- Pod restarts (crash loop indicator) ---
resource "aws_cloudwatch_metric_alarm" "pod_restart_high" {
  alarm_name          = "${local.name_prefix}-pod-restart-high"
  alarm_description   = "Pod restart count is elevated - possible CrashLoopbackoff"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.pod_restart_threshold

  treat_missing_data = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

# --- Failed nodes (node_status metric from Container Insights) ---
resource "aws_cloudwatch_metric_alarm" "nodes_not_ready" {
  alarm_name          = "${local.name_prefix}-nodes-not-ready"
  alarm_description   = "One or more Nodes are not in a Ready State"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  treat_missing_data = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

# ---------------------------------------------------------------------------
# 7. CloudWatch dashboard
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "cluster_dashboard" {
  dashboard_name = "${local.name_prefix}-eks-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Node CPU Utilization (%)"
          view   = "timeSeries"
          region = local.region
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", var.cluster_name]
          ]
          period = 60
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [{ value = var.cpu_alarm_threshold, label = "Alarm Threshold", color = "#ff0000" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Node Memory Utilization (%)"
          view   = "timeSeries"
          region = local.region
          metrics = [
            ["ContainerInsights", "node_memory_utilization", "ClusterName", var.cluster_name]
          ]
          period = 60
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [{ value = var.memory_alarm_threshold, label = "Alarm Threshold", color = "#ff0000" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Pod Restarts"
          view   = "timeSeries"
          region = local.region
          metrics = [
            ["ContainerInsights", "pod_number_of_container_restarts", "ClusterName", var.cluster_name]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Failed Node Count"
          view   = "timeSeries"
          region = local.region
          metrics = [
            ["ContainerInsights", "cluster_failed_node_count", "ClusterName", var.cluster_name]
          ]
          period = 60
          stat   = "Maximum"
          annotations = {
            horizontal = [{ value = 0, label = "Any Failure", color = "#ff0000" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Node filesystem Utilization (%)"
          view   = "timeSeries"
          region = local.region
          metrics = [
            ["ContainerInsights", "node_filesystem_utilization", "ClusterName", var.cluster_name]
          ]
          period = 60
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [{ value = var.filesystem_alarm_threshold, label = "Alarm Threshold", color = "#ff0000" }]
          }
        }
      },
    ]
  })
}
