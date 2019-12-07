terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.0"
  region = "us-west-2"
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
}
