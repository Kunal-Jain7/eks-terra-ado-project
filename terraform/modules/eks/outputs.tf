### modules/eks/outputs.tf

output "cluster_name" {
  value = aws_eks_cluster.client_eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.client_eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.client_eks_cluster.certificate_authority[0].data
  description = "Base64-encoded CA certificate for the cluster. Used by kubectl and the Kubernetes Terraform provider."
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.client_eks_cluster.vpc_config[0].cluster_security_group_id
  description = "Auto-created cluster security group ID (EKS-managed, attached to control-plane ENIs)"
}

output "cluster_oidc_issuer_url" {
  value       = aws_eks_cluster.client_eks_cluster.identity[0].oidc[0].issuer
  description = "OIDC issuer URL for the cluster. Use this to construct IRSA trust policy conditions."
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.open_id.arn
  description = "ARN of the IAM OIDC provider. Required when creating IRSA roles for controllers."
}

output "oidc_provider_url" {
  value       = replace(aws_eks_cluster.client_eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  description = "URL of the OIDC provider (without https://). Useful in IAM trust policy StringEquals conditions"
}

output "cluster_version" {
  value       = aws_eks_cluster.client_eks_cluster.version
  description = "Kubernetes version currently running on the cluster."
}
