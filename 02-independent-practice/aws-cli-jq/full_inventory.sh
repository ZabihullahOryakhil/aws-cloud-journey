#!/bin/bash

#==================================

LOGFILE="$HOME/Desktop/aws_cli/s3_inventory.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DRY_RUN=true

echo "=============================" > "$LOGFILE"
echo "S3 Full Inventory Report" >> "$LOGFILE"
echo "Run time : $TIMESTAMP" >> "$LOGFILE"
echo "=============================" >> "$LOGFILE"

echo ""
echo "🚀 Starting S3 Inventory Report..."
echo "Time: $TIMESTAMP"
echo ""

# Get target bucket or (s)
if [ $# -eq 0 ]; then
    echo "Reporting all buckets"
    BUCKETS=$(aws s3api list-buckets | jq '.Buckets[].Name')
    SINGLE_BUCKET_MODE=false
else
    BUCKET=$1
    echo "Detailed report for bucket: $BUCKET"
    BUCKETS="$BUCKET"
    SINGLE_BUCKET_MODE=true
fi

if [ -z "$BUCKETS" ]; then
    echo "❌ No buckets found in your account."
    echo "No buckets found." >> "$LOGFILE"
    exit 0
fi

TOTAL_BUCKETS=0
TOTAL_OBJECTS=0
TOTAL_SIZE=0

# Loop through bucket(s)
for BUCKET in $BUCKETS; do
    echo ""
    echo "🔍 Analyzing bucket: $BUCKET"
    echo "Bucket: $BUCKET" >> "$LOGFILE"

    # Get full objects list as JSON (using list-objects-v2)
    OBJECTS_JSON=$(aws s3api list-buckets-v2 --bucket "$BUCKETS" 2>/dev/null)

    if [ -z "$OBJECTS_JSON" ] || [ "$(echo $OBJECT_JSON)" | jq -r '.Contents | length // 0' = "0"]; then
        echo "   📭 Empty bucket"
        echo "   Objects: 0 | Size: 0 bytes" >> "$LOGFILE"
        continue
    fi

    # Use jq to extract clean data
    OBJ_COUNT=$(echo "$0BJECTS_JSON" | jq -r '.Contents | length')
    BUCKET_SIZE_BYTES=$(echo "$OBJECTS_JSON" | jq -r '[.Contents[].Size] | add // 0')
    BUCKET_SIZE_MB=$(echo "scale=2; $BUCKET_SIZE_BYTES / 1024 / 1024" | bc)


    # Show top 5 largest files
    echo " Objects : $OBJ_COUNT"
    echo " Size    : $BUCKET_SIZE_MB MB ($BUCKET_SIZE_BYTES bytes)"
    echo ""
    echo "Top 5 largest files:"
    echo "$OBJECTS_JSON" | jq -r '.Contents[] | "\(.LastModified)   \(.Size) bytes  \(.Key)"' | sort -k2 -nr | head -5

    # Log summary
    echo "   Objects: $OBJ_COUNT | Size: $BUCKET_SIZE_MB MB" >> "$LOGFILE"

    # Update totals
    TOTAL_BUCKETS=$((TOTAL_BUCKETS + 1))
    TOTAL_OBJECTS=$((TOTAL_OBJECTS + OBJ_COUNT))
    TOTAL_SIZE=$((TOTAL_SIZE + BUCKET_SIZE_BYTES))
done

# Final summary
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)

echo ""
echo "============================="
echo "✅ SUMMARY"
echo "Total buckets analyzed : $TOTAL_BUCKETS"
echo "Total objects          : $TOTAL_OBJECTS"
echo "Total storage used     : $TOTAL_SIZE_MB MB"
echo "============================="

echo "" >> "$LOGFILE"
echo "SUMMARY" >> "$LOGFILE"
echo "Total buckets : $TOTAL_BUCKETS" >> "$LOGFILE"
echo "Total objects : $TOTAL_OBJECTS" >> "$LOGFILE"
echo "Total size    : $TOTAL_SIZE_MB MB" >> "$LOGFILE"
echo "Log saved to: $LOGFILE"