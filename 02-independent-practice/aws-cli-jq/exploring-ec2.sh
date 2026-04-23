!/bin/bash

# Listing EC2 instances
# aws ec2 describe-instances --region us-east-1

# # Same but using jq to show key fields
# aws ec2 describe-instances --region us-east-1 | jq '.Reservations[].Instances[] | {
#         id:    .InstanceId,
#         type:  .InstanceType,
#         state: .State.Name,
#         ip:    .PublicIpAddress
#     }'


# # Listing only running instances
# aws ec2 describe-instances --region us-east-1 | jq '.Reservations[].Instances[] | select(.State.Name == "running") | {
#         id: .InstanceId,
#         type: .InstanceType

# }'

# # List available regions
# aws ec2 describe-regions --output table

# # list all instances types available
# aws ec2 describe-instance-types \
#     --filters "Name=instance-type,Values=t2.*" \
#     --query "InstanceType[].InstanceType" \
#     --output table

# Creating EC2 Instance

# Step 1- Getting AMI ID
aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text \
    --region us-east-1

# Step 2- Creating a key pair now
aws ec2 create-key-pair \
    --key-name aws-practice-key \
    --query "KeyMaterial" \
    --output text > ~/.ssh/aws-practice-key.pem

chmod 400 ~/.ssh/aws-practice-key.pem

aws ec2 create-key-pair --key-name aws-practice-key --query 'KeyMaterial' --output text > ~/.ssh/aws-practice-key.pem
