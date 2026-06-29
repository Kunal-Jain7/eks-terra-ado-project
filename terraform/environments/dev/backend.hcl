# Example partial backend config for the dev environment.
# Replace <ACCOUNT_ID> with the value from:
#   terraform -chdir=global/bootstrap output state_bucket_name
# Usage:
#   terraform init -backend-config=backend.hcl

bucket         = "eksplat-terraform-state-622385388668"
key            = "env/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "eksplat-terraform-locks"
encrypt        = true
