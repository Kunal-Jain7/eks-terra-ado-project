output "nodes_security_group_id" {
  value = aws_security_group.eks_sg.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "cluster_additional_security_group_id" {
  value = aws_security_group.cluster_additional.id
}

output "eks_secrets_kms_key_arn" {
  value = aws_kms_key.eks_secrets.arn
}

output "ebs_kms_key_arn" {
  value = aws_kms_key.ebs.arn
}
