#!/bin/bash


set -e

BUCKET_NAME="janan3378"
REGION="us-east-1"
ENVIRONMENT="dev"
INSTANCE_TYPE="t2.micro"

STACK_NAME="MyApp-MasterStack-${ENVIRONMENT}"
TEMPLATE_DIR="."

# COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

deploy() {
    echo -e "${GREEN}--> Real-World Nested Stack Deployment -->${NC}"

    echo -e "${YELLOW}Checking S3 bucket: ${BUCKET_NAME}...${NC}"

    if ! aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
        echo -e "${YELLOW}Bucket does not exist. Creating...${NC}"
        aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"
        echo -e "${GREEN}Bucket created.${NC}"
    else
        echo -e "${GREEN}Bucket exists.${NC}"
    fi


    echo -e "${YELLOW}Uploading all YAML templates to S3...${NC}"

    aws s3 sync "${TEMPLATE_DIR}" "s3://${BUCKET_NAME}/" \
        --exclude "*" \
        --include "*.yaml"

    echo -e "${GREEN}✅ All templates uploaded successfully.${NC}"

    # Deploying Master Stack

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

    echo -e "${GREEN}✅ Master Stack deployment started!${NC}"

    echo -e "${YELLOW}Waiting for stack to complete (this may take 3-6 minutes)...${NC}"

    if aws cloudformation wait stack-create-complete \
        --stack-name "${STACK_NAME}" \
        --region "${REGION}"; then
        echo -e "${GREEN}✅ Stack deployed successfully!${NC}"
    else
        echo -e "${RED}❌ Stack deployment failed.${NC}"
        exit 1
    fi


    # Outputs
    echo -e "\n${GREEN}--> Deployment Summary -->${NC}"
    echo -e "Stack Name : ${STACK_NAME}"
    echo -e "Region     : ${REGION}"
    echo -e "Environment: ${ENVIRONMENT}\n"

    echo -e "${YELLOW}Important Outputs:${NC}"
    aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table \
        --region "${REGION}"
        
    echo -e "\n${GREEN}You can now open the WebURL in your browser.${NC}"

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

case "$1" in
    cleanup|delete|remove)
        cleanup
        ;;
    *)
        deploy
        ;;
esac

