#!/bin/bash

# S3 Manager

# Guide
if [ $# -eq 0 ]; then
    echo "Usage: bash s3_manager.sh <bucket-name> [--cleanup]"
    echo "Example: bash s3_manager.sh bucket-janan1235"
    exit 1
fi

# Config
BUCKET=$1
REGION="us-east-1"
WORKDIR="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/test-file"
LOGFILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/s3_manager.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
CLEANUP=false

if [ "$2" == "--cleanup" ]; then
    CLEANUP=true
fi

# logging function
log() {
    echo " $1"
    echo "[$TIMESTAMP] $1" >> $LOGFILE
}

# Start
echo ""
echo "------------------------"
echo " S3 Manager"
echo " Bucket: $BUCKET"
echo " Region: $REGION"
echo "------------------------"
echo ""

echo "S3 Manager run: $TIMESTAMP" > $LOGFILE
echo "Bucket: $BUCKET" >> $LOGFILE

# Step 1: Creating a bucket if not exists
aws s3api head-bucket --bucket $BUCKET > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Bucket '$BUCKET' already exists - skipping creation"
else
    log "Creating bucket '$BUCKET'"
    aws s3 mb s3://$BUCKET --region $REGION > /dev/null

    if [ $? -eq 0 ]; then
        log "Bucket created successfully"
    else
        log "Error: Failed to create bucket"
        exit 1
    fi
fi

# creating local test files
echo ""
echo "Step 2: creating test files..."

mkdir -p $WORKDIR

echo "This is file one"   > $WORKDIR/file1.txt
echo "This is file two"   > $WORKDIR/file2.txt
echo "This is file three" > $WORKDIR/file3.txt

log "Created 3 test files in $WORKDIR"

# Step 3: Upload files one by one 
echo ""
echo "Step 3: Uploading files..."

for FILE in $WORKDIR/*.txt; do
    FILENAME=$(basename $FILE)

    aws s3 cp $FILE s3://$BUCKET/$FILENAME > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log "Uploaded: $FILENAME"
    else
        log "Error: Failed to upload $FILENAME"
    fi
done

# Step 4: Verify uplaods using jq
echo ""
echo "Step 4: Verifying uplaods..."

OBJECTS_JSON=$(aws s3api list-objects-v2 --bucket $BUCKET)
OBJ_COUNT=$(echo $OBJECTS_JSON | jq '.Contents | length // 0')

log "Objects in bucket: $OBJ_COUNT"

echo $OBJECTS_JSON | jq -r '.Contents[] | " verified: " + .Key + " (" + (.Size|tostring) + " bytes)"'

# Step 5 - Delete a specific file
echo ""
echo "Step 5: Deleting file3.txt..."

aws s3 rm s3://$BUCKET/file3.txt > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Deleted: file3.txt"
else
    log "Error: Could not delete file3.txt"
fi

AFTER_DELETE=$(aws s3api list-objects-v2 --bucket $BUCKET \
    | jq '.Contents | length // 0')

log "Objects remaining after delete: $AFTER_DELETE"

# Step 6: Cleanup (only if passed)
echo ""
if [ "$CLEANUP" == "true" ]; then
    echo "Step 6: cleanup - Deleting entire bucket..."
    aws s3 rb s3://$BUCKET --force > /dev/null 2>&1


    if [ $? -eq 0 ]; then
        log "Bucket '$BUCKET' deleted"
    else
        log "ERROR: Could not delete bucket"
    fi
else
    echo "[ Step 6 ] Skipping cleanup (pass --cleanup to delete bucket)"
    log "Cleanup skipped"
fi

# Summary
echo ""
echo "Done. Log saved to:"
echo "$LOGFILE"
echo "-------------------------"