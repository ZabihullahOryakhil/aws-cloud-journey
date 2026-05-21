# #!/bin/bash

# set -e Exit on error

# BUCKET_NAME="janan3378"
# REGION="us-east-1"
# ENVIRONMENT="Practice"
# INSTANCE_TYPE="t2.micro"


# STACK_NAME="MyApp-MasterStack-${ENVIRONMENT}"
# TEMPLATE_DIR="."


# # Color
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# NC='\033[0m'

# if [ $1 == "--cleanup" ]: then


# echo -e "${GREEN}--- Starting Deployment to Bucket: ${BUCKET_NAME} ---${NC}"


# echo -e "${YELLOW}Checking S3 Bucket: ${BUCKET_NAME}...${NC}"

# if ! aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
#     echo -e "${RED}Bucket ${BUCKET_NAME} does not exist!${NC}"
#     echo "Creating the bucket: ${BUCKET_NAME}"

#     aws s3 mb s3://${BUCKET_NAME} --region ${REGION}
# else
#     echo -e "${GREEN}Bucket ${BUCKET_NAME} exists. ${NC}"
# fi

# echo -e "${YELLOW}Uploading YAML templates to s3://${BUCKET_NAME}/ ... ${NC}"

# aws s3 sync "${TEMPLATE_DIR}" "s3://${BUCKET_NAME}/" \
#     --exclude "*" \
#     --include "*.yaml" \
#     --include "master.yaml"

# echo -e "${GREEN}All templates uploaded successfully. ${NC}"


# # Deploying master Stack
# echo -e "${YELLOW}Deploying Master Stack: ${STACK_NAME}...${NC}"

# aws cloudformation deploy \
#     --stack-name "${STACK_NAME}" \
#     --template-file master.yaml \
#     --parameter-overrides \
#         EnvironmentName="${ENVIRONMENT}" \
#         InstanceType="${INSTANCE_TYPE}" \
#     --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
#     --region "${REGION}" \
#     --no-fail-on-empty-changeset

# echo -e "${GREEN}Master Stack deployment started successfully!${NC}"


# # Waiting and SHOW output
# echo -e "${YELLOW}Waiting for stack to complete...${NC}"
# aws cloudformation wait stack-create-complete \
#     --stack-name "${STACK_NAME}" \
#     --region "${REGION}" || true

# echo -e "${GREEN}--- Deployment Completed! ---${NC}"
# echo -e "Stack Name : ${STACK_NAME}"
# echo -e "Bucket     : ${BUCKET_NAME}\n"


# echo -e "${YELLOW}Stack Outputs:${NC}"
# aws cloudformation describe-stacks \
#     --stack-name "${STACK_NAME}" \
#     --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
#     --output table \
#     --region "${REGION}"




#!/bin/bash
# ---
# AWS Nested CloudFormation Deployment Script
# Bucket: janan3378
# ---

set -e  # Exit on error

# ---= CONFIGURATION ---=
BUCKET_NAME="janan3378"
REGION="us-east-1"
ENVIRONMENT="Practice"
INSTANCE_TYPE="t2.micro"

STACK_NAME="MyApp-MasterStack-${ENVIRONMENT}"
TEMPLATE_DIR="."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ---= FUNCTIONS ---=

deploy() {
    echo -e "${GREEN}--- Starting Deployment to Bucket: ${BUCKET_NAME} ---${NC}"

    # Check bucket
    if ! aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
        echo -e "${RED}Bucket ${BUCKET_NAME} does not exist!${NC}"
        echo "Creating the bucket: ${BUCKET_NAME}"
        aws s3 mb s3://${BUCKET_NAME} --region ${REGION}
    else
        echo -e "${GREEN}Bucket ${BUCKET_NAME} exists.${NC}"
    fi

    # Upload templates
    echo -e "${YELLOW}Uploading YAML templates...${NC}"
    aws s3 sync "${TEMPLATE_DIR}" "s3://${BUCKET_NAME}/" \
        --exclude "*" \
        --include "*.yaml"

    echo -e "${GREEN}Templates uploaded.${NC}"

    # Deploy stack
    echo -e "${YELLOW}Deploying Master Stack: ${STACK_NAME}...${NC}"
    aws cloudformation deploy \
        --stack-name "${STACK_NAME}" \
        --template-file master.yaml \
        --parameter-overrides \
            EnvironmentName="${ENVIRONMENT}" \
            InstanceType="${INSTANCE_TYPE}" \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --region "${REGION}" \
        --no-fail-on-empty-changeset

    echo -e "${GREEN}Deployment started! Waiting for completion...${NC}"
    aws cloudformation wait stack-create-complete --stack-name "${STACK_NAME}" --region "${REGION}" || true

    echo -e "${GREEN}--- Deployment Completed ---${NC}"
    aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table \
        --region "${REGION}"
}

cleanup() {
    echo -e "${RED}--- Starting Cleanup ---${NC}"

    # 1. Delete CloudFormation Stack
    echo -e "${YELLOW}Deleting CloudFormation Stack: ${STACK_NAME}...${NC}"
    if aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${REGION}" &>/dev/null; then
        aws cloudformation delete-stack --stack-name "${STACK_NAME}" --region "${REGION}"
        echo -e "${YELLOW}Waiting for stack deletion to complete...${NC}"
        aws cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}" --region "${REGION}"
        echo -e "${GREEN}CloudFormation Stack deleted successfully.${NC}"
    else
        echo -e "${YELLOW}Stack ${STACK_NAME} does not exist.${NC}"
    fi

    # 2. Empty and Delete S3 Bucket
    echo -e "${YELLOW}Emptying and deleting S3 bucket: ${BUCKET_NAME}...${NC}"
    aws s3 rm "s3://${BUCKET_NAME}/" --recursive || true
    aws s3 rb "s3://${BUCKET_NAME}" --force || true
    echo -e "${GREEN}S3 Bucket cleaned up.${NC}"

    echo -e "${GREEN}--- Cleanup Completed ---${NC}"
}

# ---= MAIN LOGIC ---=

case "$1" in
    cleanup|delete|remove)
        cleanup
        ;;
    *)
        deploy
        ;;
esac