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
}

# Default provider — all regional resources (ECS, RDS, ALB, etc.)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# us-east-