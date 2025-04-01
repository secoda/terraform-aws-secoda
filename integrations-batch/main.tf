data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_default_tags" "def_tags" {}

data "aws_organizations_organization" "org" {}
