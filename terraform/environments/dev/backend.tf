# Partial backend configuration.
# Concrete values (bucket / key / region / dynamodb_table) are supplied at
# `terraform init` time, either via:
#   terraform init -backend-config=backend.hcl
# or via -backend-config flags injected by the Azure DevOps pipeline.
# This keeps the AWS account ID (embedded in the bucket name) out of the
# logic files and lets the same code be reused across environments.
terraform {
  backend "s3" {}
}
