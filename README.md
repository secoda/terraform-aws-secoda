# AWS Terraform

## Quick Start
```hcl
module "secoda" {
  source      = "secoda/secoda/aws"
  version     = "2025.3.7"
  name        = "secoda"
  environment = "production"
  aws_region  = "us-east-1"
  docker_password = "" # Must be filled in.
}
```

## Setup Guide

### Updating to the Latest Version
1. Pull the latest terraform OR if using Secoda as a terraform module, bump the pinned version
2. Reapply the terraform
3. Wait for a new ECS task to start automatically (use refresh button to check)

### SSO Configuration
Supported providers:
- Google
- Microsoft
- Okta
- OneLogin
- SAML2.0

### Hashicorp Cloud Setup
1. Ensure you are a member of a _Terraform Cloud_ account
2. Run `terraform login` in this directory
3. In `versions.tf`, uncomment and update the following:
```yaml
backend "remote" {
    organization = "secoda"  # Replace with your organization name
}
```

## Infrastructure Details

### Network Access
- Load balancer: Publicly accessible (DNS name provided after `terraform apply`)
  - Note: Initial setup has ~5 minute delay for target registration
- Containers: Located in private subnets (VPC access only)
  - For maintenance: Consider using Tailscale
- Recommended: Use _Cloudflare ZeroTrust_ for access control

### Integration Network Configuration
Default: Secoda runs in a separate VPC

Connection Options:
1. **Default: VPC to Internet to VPC**
   - Whitelist and configure NAT Gateway EIP security rules
   - Works out of the box

2. **VPC to VPC**
   - Uses AWS VPC Peering
   - Requires manual setup or additional terraform code
   - Whitelist security rules for AWS VPC network access

3. **Intra-VPC**
   - Place Secoda in the same VPC as your data integrations (Redshift, Postgres, etc.)
   - Configure security rules for resource access
   - Override VPC variables in `onprem.tf`

## Troubleshooting

Common Issues:
1. **MalformedPolicyDocumentException**
   - Error: "Policy contains a statement with one or more invalid service principals"
   - Solution: Use different AWS administrator account or create new one

2. **Subnet Creation Error**
   - Error: "Subnets can currently only be created in specific availability zones"
   - Solution: Ensure `tfvars` file and `AWS_REGION` environment variable match

3. **ELBv2 Listener Error**
   - Error: "Certificate ARN is not valid"
   - Solution: Verify certificate is in same region as deployment
