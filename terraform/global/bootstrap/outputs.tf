output "state_bucket_name" {
  value = module.state_backend.bucket_name
}

output "state_bucket_arn" {
  value = module.state_backend.bucket_arn
}

output "lock_table_name" {
  value = module.state_backend.dynamodb_table_name
}

output "kms_key_arn" {
  value = module.state_backend.kms_key_arn
}

output "backend_config_example" {
  description = "Copy these values into environments/<env>/backend.hcl (set key per environment)"
  value       = <<-EOT
    bucket = "${module.state_backend.bucket_name}
    region = "${var.aws_region}
    dynamodb_table = "${module.state_backend.dynamodb_table_name}"
    encypt = true
  EOT
}
