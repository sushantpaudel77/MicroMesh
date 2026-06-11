terraform {
  backend "s3" {
    bucket = "ecommerce-terraform-state-cloudnerd"
    key    = "stage/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
