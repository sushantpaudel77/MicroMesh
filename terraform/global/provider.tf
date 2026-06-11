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

# State backend resources must live in us-east-1 (matches all environment backend configs).
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = var.tags
  }
}
