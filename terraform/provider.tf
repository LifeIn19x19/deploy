terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = {
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
}
