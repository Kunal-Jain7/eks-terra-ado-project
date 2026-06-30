# ── General ──────────────────────────────────────────────────────────────────

aws_region   = "us-east-1"
project_name = "eksplat"
environment  = "dev"

tags = {
  Owner      = "platform-team"
  CostCenter = "eng-platform"
}


# ── Network ───────────────────────────────────────────────────────────────────
vpc_cidr           = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.16.0/20", "10.10.32.0/20"]

# dev is cost-optimized: one NAT Gateway shared across both AZs.
# qa/prod will set this to false (NAT Gateway per AZ) when those
# environments are composed.
single_nat_gateway = true

# ── Security ──────────────────────────────────────────────────────────────────
alb_ingress_cidrs = ["0.0.0.0/0"]

# Trusted CIDRs (office/VPN) granted extra HTTPS access to the EKS API
# server, e.g. ["203.0.113.0/24"]. Empty = no additional restriction beyond
# the cluster's own public/private endpoint config.
admin_access_cidrs = []

# ── EKS cluster ───────────────────────────────────────────────────────────────
cluster_name       = "eksplat-dev-eks"
kubernetes_version = "1.30"

# dev: public+private endpoint; lock to private-only for prod
endpoint_public_access = true
public_access_cidrs    = ["0.0.0.0/0"]

# null = use EKS-default addon version for k8s 1.30
# Pin to specific versions for prod, e.g.:
#   "vpc-cni" = "v1.18.3-eksbuild.1"
addon_versions = {
  "vpc-cni"            = null
  "coredns"            = null
  "kube-proxy"         = null
  "aws-ebs-csi-driver" = null
}

# ── Node group ────────────────────────────────────────────────────────────────
node_desired_size      = 2
node_group_name_suffix = "general"
node_instance_type     = "c7i-flex.large"
node_max_size          = 4
node_min_size          = 1

# ── Monitoring ────────────────────────────────────────────────────────────────
log_retention_days         = 30
alarm_email                = "kunal70223@gmail.com" # set to "you@example.com" to receive alerts
cpu_alarm_threshold        = 80
memory_alarm_threshold     = 80
filesystem_alarm_threshold = 85
pod_restart_threshold      = 5
