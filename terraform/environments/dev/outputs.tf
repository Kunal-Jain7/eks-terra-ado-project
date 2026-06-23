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

output "cluster_role_arn" {
  value = module.iam.cluster_role_arn
}

output "node_role_arn" {
  value = module.iam.node_role_arn
}

output "node_instance_profile_name" {
  value = module.iam.node_instance_profile_name
}

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
