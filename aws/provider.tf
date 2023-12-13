terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.28.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region
}

data "aws_caller_identity" "current" {}