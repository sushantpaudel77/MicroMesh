terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket  = "ecommerce-terraform-state-cloudnerd"
    key     = "stage/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Default provider — all regional resources (ECS, RDS, ALB, etc.)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# us-east-1 alias — required for CloudFront WAF (scope = CLOUDFRONT)
# and the frontend S3 bucket (served via CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = var.tags
  }
}
