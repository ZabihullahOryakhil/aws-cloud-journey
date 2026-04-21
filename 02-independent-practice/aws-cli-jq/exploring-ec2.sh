#!/bin/bash

# Listing EC2 instances
aws ec2 describe-instances --region us-east-1

# Same but using jq to show key fields
aws ec2 describe-instances --region us-east-1 | jq '.Reservations[].Instances[] | {
        id:    .InstanceId,
        type:  .InstanceType,
        state: .State.Name,
        ip:    .PublicIpAddress
    }'


# Listing only running instances
aws ec2 describe-instances --region us-east-1 | jq '.Reservations[].Instances[] | select(.State.Name == "running") | {
        id: .InstanceId,
        type: .InstanceType

}'

# List available regions
aws ec2 describe-regions --output table

# list all instances types available
aws ec2 describe-instance-types \
    --filters "Name=instance-type,Values=t2.*" \
    --query "InstanceType[].InstanceType" \
    --output table
