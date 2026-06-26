### global/bootstrap
###
### Runs ONCE, manually or via a dedicated one-time pipeline stage, to create
### the S3 bucket + DynamoDB table that every environment's remote backend
### depends on. Intentionally uses LOCAL state - this configuration creates
### the remote backend, so it cannot depend on it.
###
### After the first successful `terraform apply` here:
###   1. Note the outputs (state_bucket_name, lock_table_name).
###   2. Securely back up the local terraform.tfstate file for this folder
###      (e.g. encrypted storage outside the repo, or your team's secrets vault).
###   3. Fill in environments/<env>/backend.hcl with the bucket name and run
###      `terraform init -backend-config=backend.hcl` in each environment.

terraform {
  required_version = ">= 1.15.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "state_backend" {
  source = "../../modules/state-backend"

  project_name = var.project_name
  tags         = var.tags
}
