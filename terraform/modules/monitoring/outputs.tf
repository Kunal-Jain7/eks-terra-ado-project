### modules/monitoring/outputs.tf

output "cloudwatch_kms_key_arn" {
  value       = aws_kms_key.cloudwatch.arn
  description = "ARN of the KMS key used to encrypt CloudWatch log groups"
}

output "control_plane_log_group_name" {
  value       = aws_cloudwatch_log_group.eks_control_plane_loggroup.name
  description = "CloudWatch log group name for EKS control plane logs"
}

output "container_insights_log_group_name" {
  value       = aws_cloudwatch_log_group.container_insights.name
  description = "CloudWatch log group name for Container Insights performance metrics"
}

output "application_log_group_name" {
  value       = aws_cloudwatch_log_group.application_logs.name
  description = "CloudWatch log group name for application (pod) logs"
}

output "cloudwatch_agent_role_arn" {
  value       = aws_iam_role.cloudwatch_agent_role.arn
  description = "IRSA role ARN for the CloudWatch Observability addon agent"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.alarms.arn
  description = "SNS topic ARN for CloudWatch alarm notifications"
}

output "dashboard_name" {
  value       = aws_cloudwatch_dashboard.cluster_dashboard.dashboard_name
  description = "CloudWatch dashboard name"
}

output "dashboard_url" {
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.cluster_dashboard.dashboard_name}"
  description = "Direct URL to the CloudWatch dashboard in the AWS console"
}

