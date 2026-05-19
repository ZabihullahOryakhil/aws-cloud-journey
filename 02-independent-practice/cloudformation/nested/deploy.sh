#!/bin/bash

#  Nested Stack Deploy Script


STACK_NAME="nested-practice-stack"
REGION="us-east-1"
TEMPLATES_BUCKET="cfn-templates-janan-2026"  # change this
TEMPLATES_DIR="$(dirname "$0")"

log() { echo "  [$(date '+%H:%M:%S')] $1"; }

# ── Cleanup function 
if [ "$1" == "--cleanup" ]; then
    log "Cleaning up..."
    aws cloudformation delete-stack \
        --stack-name $STACK_NAME \
        --region $REGION

    aws cloudformation wait stack-delete-complete \
        --stack-name $STACK_NAME \
        --region $REGION

    aws s3 rb s3://$TEMPLATES_BUCKET --force > /dev/null
    log "Everything deleted"

    exit 0
fi

# ── Step 1: Create templates bucket 
log "Creating templates bucket..."
aws s3 mb s3://$TEMPLATES_BUCKET --region $REGION > /dev/null 2>&1
log "Bucket ready: $TEMPLATES_BUCKET"

# ── Step 2: Upload all templates to S3 g "Uploading templates to S3..."
for TEMPLATE in $TEMPLATES_DIR/*.yaml; do
    FILENAME=$(basename $TEMPLATE)
    aws s3 cp $TEMPLATE s3://$TEMPLATES_BUCKET/$FILENAME > /dev/null
    log "Uploaded: $FILENAME"
done

# ── Step 3: Deploy master stack 
log "Deploying master stack..."
aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://$TEMPLATES_DIR/master.yaml \
    --parameters file://$TEMPLATES_DIR/parameters.json \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

# ── Step 4: Wait for completion 
log "Waiting for stack to complete..."
aws cloudformation wait stack-create-complete \
    --stack-name $STACK_NAME \
    --region $REGION

# ── Step 5: Get outputs 
log "Stack complete. Outputs:"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query "Stacks[0].Outputs" \
    --output table \
    --region $REGION
