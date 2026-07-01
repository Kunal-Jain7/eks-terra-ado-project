/*module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  cluster_name         = var.cluster_name
  tags                 = var.tags
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "security" {
  source = "../../modules/security"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  alb_ingress_cidrs  = var.alb_ingress_cidrs
  admin_access_cidrs = var.admin_access_cidrs
  tags               = var.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  cluster_role_arn   = module.iam.cluster_role_arn

  # Pass the whole iam module so Terraform waits for policy attachments
  # before attempting cluster creation
  cluster_role_policy_dependency = module.iam

  subnet_ids                           = module.network.private_subnet_ids
  node_security_group_id               = module.security.nodes_security_group_id
  cluster_additional_security_group_id = module.security.cluster_additional_security_group_id
  kms_key_arn                          = module.security.ebs_kms_key_arn

  endpoint_public_access = var.endpoint_public_access
  public_access_cidrs    = var.public_access_cidrs
  addon_versions         = var.addon_versions

  tags = var.tags
}

module "nodegroup" {
  source = "../../modules/nodegroup"

  cluster_name           = module.eks.cluster_name
  environment            = var.environment
  node_group_name_suffix = var.node_group_name_suffix
  node_role_arn          = module.iam.node_role_arn
  subnet_ids             = module.network.private_subnet_ids
  instance_type          = var.node_instance_type
  desired_size           = var.node_desired_size
  max_size               = var.node_max_size
  min_size               = var.node_min_size
  ebs_kms_key_arn        = module.security.ebs_kms_key_arn
  tags                   = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  log_retention_days         = var.log_retention_days
  alarm_email                = var.alarm_email
  cpu_alarm_threshold        = var.cpu_alarm_threshold
  memory_alarm_threshold     = var.memory_alarm_threshold
  filesystem_alarm_threshold = var.filesystem_alarm_threshold
  pod_restart_threshold      = var.pod_restart_threshold

  tags = var.tags
}
*/
