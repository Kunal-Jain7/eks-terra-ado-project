output "cluster_role_arn" {
  value = aws_iam_role.cluster_role.arn
}

output "cluster_role_name" {
  value = aws_iam_role.cluster_role.name
}

output "node_role_arn" {
  value = aws_iam_role.node_role.arn
}

output "node_role_name" {
  value = aws_iam_role.node_role.name
}

output "node_instance_profile_name" {
  value = aws_iam_instance_profile.node_instanceprof.name
}

output "node_instance_profile_arn" {
  value = aws_iam_instance_profile.node_instanceprof.arn
}

output "oidc_provider_arn" {
  value = length(aws_iam_openid_connect_provider.open_id) > 0 ? aws_iam_openid_connect_provider.open_id[0].arn : null
}
