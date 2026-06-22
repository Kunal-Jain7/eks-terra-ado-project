### network module
### Builds a VPC with public + private subnets across N availability zones,
### one Internet Gateway, one NAT Gateway per AZ (or a single shared one for
### cost-sensitive environments), and the associated route tables.
### Subnets are pre-tagged for EKS / AWS Load Balancer Controller
### auto-discovery, even though the cluster doesn't exist yet at this phase.

locals {
  public_subnets = {
    for idx, az in var.availability_zones :
    az => {
      cidr = var.public_subnet_cidrs[idx]
    }
  }

  private_subnets = {
    for idx, az in var.availability_zones :
    az => {
      cidr = var.var.private_subnet_cidrs[idx]
    }
  }

  nat_keys = var.single_nat_gateway ? toset(["single"]) : toset(var.availability_zones)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Managed_By  = "Terraform"
  })
}

# ---------------------------------------------------------------------------
# VPC + Internet Gateway
# ---------------------------------------------------------------------------

resource "aws_vpc" "client_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "client_ig" {
  vpc_id = aws_vpc.client_vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
resource "aws_subnet" "public_subnet" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.client_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                                        = "${var.project_name}-${var.environment}-public-${each.key}"
    Tier                                        = "public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  })
}

resource "aws_subnet" "private_subnet" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.client_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(local.common_tags, {
    Name                                        = "${var.project_name}-${var.environment}-private-${each.key}"
    Tier                                        = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  })
}

# ---------------------------------------------------------------------------
# NAT Gateway(s)
# ---------------------------------------------------------------------------

