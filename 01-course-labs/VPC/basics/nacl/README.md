## Get VPC ID
```sh
aws ec2 describe-vpcs \
--filters "Name=tag:Name,Values=nacl-example-vpc" \
--query "Vpcs[].VpcId" --output text
```

## VPC_ID

VPC_ID= vpc-0a6a74ed8011a5ace

## NACL

```sh
aws ec2 create-network-acl --vpc-id vpc-0a6a74ed8011a5ace
```

## Get the Amazon linux 2 AMI ID in us-east-1
```sh
aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text
```