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