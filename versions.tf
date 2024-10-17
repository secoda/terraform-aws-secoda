terraform {
  required_version = ">= 1.3.5, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0, <6.0.0"
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
