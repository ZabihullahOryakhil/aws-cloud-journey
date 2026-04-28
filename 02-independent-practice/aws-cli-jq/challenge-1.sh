#!/bin/bash

# Challenge 1- S3 Multi-Region Scanner

# What it should do:
# 1. List all S3 buckets
# 2. For each bucket find its actual region
# 3. Check if versioning is enabled
# 4. Check if encryption is enabled
# 5. Check if public access is blocked
# 6. Generate a security score per bucket (0-3)
#    +1 versioning on
#    +1 encryption on
#    +1 public access blocked
# 7. Save full report to log
# 8. Print summary with total buckets and average score

LOGFILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/challenge1.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TOTAL_SCORE=0
TOTAL_BUCKETS=0


log() { echo "  $1"; echo "[$1]" >> $LOGFILE; }
warning() { echo "  WARNING: $1"; echo "[WARNING] $1" >> $LOGFILE; }
ok() { echo "  OK: $1"; echo "[OK] $1" >> $LOGFILE; }

echo "S3 Security Scanner — $TIMESTAMP"
echo ""

BUCKETS=$(aws s3api list-buckets | jq -r '.Buckets[].Name')

for BUCKET in $BUCKETS; do
    SCORE=0
    TOTAL_BUCKETS=$((TOTAL_BUCKETS + 1))

    echo "Bucket: $BUCKET"

    # TODO 1: get bucket region using get-bucket-location
    REGION=$(aws s3api get-bucket-location --bucket "$BUCKET" | jq -r '.LocationConstraint // "us-east-1"')

        #Hundling cases where location constraint is "null"
    if [ "$REGION" == "null" ] || [ -z "$REGION" ]; then
        REGION="us-east-1"
    fi

    log "Region: $REGION"

    # TODO 2: Check Versioning 
    VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET" | jq -r '.Status // "Disabled"')

    # if not enabled print Disabled
    if [ -z "$VERSIONING" ]; then
        VERSIONING="Disabled"
    fi
    
    log "Versioning Status: $VERSIONING"
    
    if [ "$VERSIONING" == "Enabled" ]; then
        ok "Versioning is enabled for $BUCKET"
        SCORE=$((SCORE + 1))
    else
        warning "Versioning is NOT enabled for $BUCKET"
    fi


    # TODO 3: Check encryption
    ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET" --region "$REGION" 2>/dev/null | jq -r '.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm // "None"')

    log "Encryption Status: $ENCRYPTION"

    if [ "$ENCRYPTION" != "None" ]; then
        ok "Encryption is enabled using $ENCRYPTION"
        SCORE=$((SCORE + 1))
    else
        warning "No default encryption found for $BUCKET"
    fi


    # TODO 4: Check public access block
    PUBLIC_BLOCK=$(aws s3api get-public-access-block --bucket "$BUCKET" 2>/dev/null | jq -r '.PublicAccessBlockConfiguration | [.BlockPublicAcls, .IgnorePublicPolicy, .RestrictPublicBuckets] | all')

    log "Public Block Status: $PUBLIC_BLOCK"

    if [ "$PUBLIC_BLOCK" == "true" ]; then
        ok "All Public Access Blocks are enabled for $BUCKET"
        SCORE=$((SCORE + 1))
    else
        warning "Public Access Blocks are Not fully enabled for $BUCKET"
    fi


    TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
    echo " Security Score: $SCORE/3"
    echo ""
done

# TODO 5: Summary
echo ""
echo "Summary"
echo "Total Bucket(s): $TOTAL_BUCKETS"
echo "Total Score: $TOTAL_SCORE"
# AVERAGE_SCORE=$((TOTAL_SCORE / $TOTAL_BUCKETS)) - I forget to handle division by zero

if [ "$TOTAL_BUCKETS" -gt 0 ]; then 
    AVERAGE_SCORE=$(echo "scale=2; $TOTAL_SCORE / $TOTAL_BUCKETS" | bc -l)
    echo "Average score per bucket: $AVERAGE_SCORE"
else
    echo "Average score per bucket: 0"
fi

# echo "Average score per bucket: $AVERAGE_SCORE"
