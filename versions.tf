terraform {
  required_version = ">= 1.3.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
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
