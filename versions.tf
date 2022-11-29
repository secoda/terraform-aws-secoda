terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74.3"
    }
  }

  # backend "remote" {
  #   # If using terraform cloud, please replace `organization = "secoda"` with your organization name.
  #   organization = "secoda"
  #   workspaces {
  #     name = "secoda-on-premise-test"
  #   }
  # }
}
