output "node_group_name" {
  value = aws_eks_node_group.eks_nodegroup.node_group_name
}

output "node_group_arn" {
  value = aws_eks_node_group.eks_nodegroup.arn
}

output "node_group_status" {
  value = aws_eks_node_group.eks_nodegroup.status
}

output "node_group_resources" {
  value = aws_eks_node_group.eks_nodegroup.resources
}

output "launch_template_id" {
  value = aws_launch_template.eks_nodes.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.eks_nodes.latest_version
}
