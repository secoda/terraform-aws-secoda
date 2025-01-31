# AWS Terraform

```hcl
module "secoda" {
  source  = "secoda/secoda/aws"
  version     = "2025.1.11"

  name        = "secoda"
  environment = "production"

  aws_region = "us-east-1"

  docker_password = "" # Must be filled in.
}
```

## Updating to the latest version

1. Pull the latest terraform OR if using Secoda as a terraform module, bump the pinned version. Reapply the terraform.
2. Wait for a new ECS task to start automatically. Hit the refresh button to check. It should pull the latest version of Secoda.

## SSO Options

- Google
- Microsoft
- Okta
- OneLogin
- SAML2.0

## Troubleshooting / FAQ

`MalformedPolicyDocumentException: Policy contains a statement with one or more invalid service principals`: please try using a different AWS administrator account, or create a new one with a different name.

`Subnets can currently only be created in the following availability zones: us-west-1b, us-west-1c`: This is due to using inconsistent regions in the `tfvars` file and the `AWS_REGION` environment variable. Make sure these are consistent.

`Error: error creating ELBv2 Listener (arn:aws:elasticloadbalancing:***): ValidationError: Certificate ARN 'arn:aws:acm:us-west-1:482836992928:certificate/***' is not valid`: This is due to the certificate being in a different region than the deployment.

## Hashicorp Cloud

To store state in Hashicorp cloud, which we recommend, please complete the following steps. You should be a member of a _Terraform Cloud_ account before proceeding.

In this directory, run `terraform login`. In `versions.tf` please uncomment the following lines and replace `secoda` with your organization name.

```yaml
backend "remote" {
organization = "secoda"
}
```

## Connecting to the infrastructure

- Load balancer is publicly accessible by default (DNS name is returned after running `terraform apply`). There will be a delay on first setup as the registration target happens ~5 minutes.
- Containers are in private subnets by default. They cannot be accessed from outside the network (VPC). If you need to do maintenance, we suggest using a solution like Tailscale.
- We suggest using _Cloudflare ZeroTrust_ to limit access to Secoda.

## Network configuration for integrations

By default, this terraform code will put the on-premise version of Secoda in a separate VPC (#1 below).

There are three different ways of connecting your on-premise integrations to Secoda:

1. (Default) Whitelisting and setting up security rules for the NAT Gateway EIP to your resource. **(VPC to Internet to VPC)**
   - Works OOTB.
2. AWS VPC Peering and whitelisting security rules for access from the AWS VPC network. **(VPC to VPC)**
   - Requires manual setup or additional terraform code.
3. Put Secoda in the same VPC and setup security rules to your resource. **(intra-VPC)**
   - You can override VPC variables in `onprem.tf` to achieve this.
