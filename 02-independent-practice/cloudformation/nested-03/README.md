# AWS CloudFormation — Modular Nested Stack

A multi-tier AWS infrastructure stack built with CloudFormation, broken into dedicated layers and wired together through a single master nested stack.


# Architecture
```yaml
master.yaml
├── network.yaml    - VPC, public & private subnets, NAT Gateway
├── security.yaml   - Security groups (HTTP/HTTPS ingress)
├── iam.yaml        - EC2 instance role with scoped S3 access
├── storage.yaml    - S3 bucket (encrypted, versioning-ready)
└── compute.yaml    - EC2 web server (Amazon Linux 2023, auto-configured via UserData)
```


# Prerequisites
- AWS CLI installed and configured (aws configure)
- An IAM user or role with permissions to deploy CloudFormation, EC2, S3, IAM, and VPC resources
- The S3 bucket name in deploy.sh updated to something unique (the default janan3378 is just a placeholder)

# Deploy
`./deploy.sh`
This script will:

1. Create the S3 bucket if it doesn't already exist
2. Upload all .yaml templates to S3
3. Deploy the master nested stack via aws cloudformation deploy
4. Wait for completion and print all stack outputs

Note: Deployment takes roughly 3-6 minutes

# Clean Up
`./deploy.sh cleanup`
This will delete the CloudFormation stack and empty + remove the S3 bucket. Run this when you're done to avoid ongoing NAT Gateway charges


# About
The EC2 instance runs Apache with a basic HTML page, but since it's in the private subnet, you'd need a Load Balancer (ELB) or bastion host to reach it. That's a natural next step if you want to extend this.

# Cost Note
The Nat Gateway(~$0.045/hr) is the main cost driver here. Don't leave this stack running longer than you need it.