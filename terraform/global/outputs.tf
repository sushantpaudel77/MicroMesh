output "state_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "Terraform state S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_config" {
  description = "Backend configuration for each environment"
  value = {
    for env in var.environments : env => {
      bucket         = aws_s3_bucket.terraform_state.id
      key            = "${env}/terraform.tfstate"
      region         = var.aws_region
      encrypt        = true
    }
  }
}