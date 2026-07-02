# ── Network ──────────────────────────────────────────────────────────────────
/*
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "nat_gateways_ids" {
  value = module.network.nat_gateway_ids
}

# ── IAM ───────────────────────────────────────────────────────────────────────

output "cluster_role_arn" {
  value = module.iam.cluster_role_arn
}

output "node_role_arn" {
  value = module.iam.node_role_arn
}

output "node_instance_profile_name" {
  value = module.iam.node_instance_profile_name
}

# ── Security ──────────────────────────────────────────────────────────────────

output "nodes_security_group_id" {
  value = module.security.nodes_security_group_id
}

output "alb_security_group_id" {
  value = module.security.alb_security_group_id
}

output "eks_secrets_kms_key_arn" {
  value = module.security.eks_secrets_kms_key_arn
}

output "ebs_kms_key_arn" {
  value = module.security.ebs_kms_key_arn
}

# ── EKS ───────────────────────────────────────────────────────────────────────

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN — needed when creating IRSA roles for controllers"
}

output "oidc_provider_url" {
  value       = module.eks.oidc_provider_url
  description = "OIDC provider URL (without https://) — used in IAM trust policy conditions"
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

# ── Node group ────────────────────────────────────────────────────────────────

output "node_group_name" {
  value = module.nodegroup.node_group_name
}

output "node_group_status" {
  value = module.nodegroup.node_group_status
}

# ── Convenience: kubeconfig update command ────────────────────────────────────

output "kubeconfig_command" {
  description = "Run this after apply to update your local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
*/
# ── Monitoring ────────────────────────────────────────────────────────────────
/*
output "control_plane_log_group_name" {
  value = module.monitoring.control_plane_log_group_name
}
*/
/*
output "container_insights_log_group_name" {
  value = module.monitoring.container_insights_log_group_name
}

output "sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

output "dasboard_url" {
  description = "Open this URL in your browser to view the cluster health dashboard"
  value       = module.monitoring.dashboard_url
}
*/
