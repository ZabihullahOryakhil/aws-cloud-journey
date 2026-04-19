#!/bin/bash

#-------Config------------
LOGFILE="$HOME/Desktop/aws_cli/s3_report.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TOTAL_OBJECTS=0

#-----------START-------------
echo ""
echo "S3 full report"
echo "$TIMESTAMP"

echo "============" > $LOGFILE
echo "S3 Report: $TIMESTAMP" >> $LOGFILE
echo "============" >> $LOGFILE

#================ Get all Bucket names
BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

#------------------------ Check if any bucket exists ------------------
if [ -z "$BUCKETS" ]; then
    echo "No buckets found in your account"
    exit 0
fi

#============ loop through every bucket -------------------
for BUCKET in $BUCKETS; do
    echo ""
    echo "Bucket: $BUCKET"
    echo "------------"


    # Count objects in this bucket
    OBJ_COUNT=$(aws s3 ls s3://$BUCKET --recursive 2>/dev/null | wc -l)

    # Get total size
    SIZE=$(aws s3 ls s3://$BUCKET --recursive --summarize 2>/dev/null \
        | grep "Total Size" \
        | awk '{print $3}')

    # Hundle empty bucket
    if [ -z "$SIZE" ]; then
        SIZE=0
    fi
    
    echo " Objects : $OBJ_COUNT"
    echo " Size    : $SIZE bytes"

    # adding to running total
    TOTAL_OBJECTS=$((TOTAL_OBJECTS + OBJ_COUNT))

    # log it
    echo "Bucket: $BUCKET | Objects: $OBJ_COUNT | Size: $SIZE bytes" >> $LOGFILE
done

# =================== Summary ==============
echo ""
echo "===================="
echo "Total buckets: $(echo $BUCKETS | wc -w)"
echo "Total objects: $(echo $TOTAL_OBJECTS)"

echo "-----------------------------"          >> $LOGFILE
echo "Total buckets : $(echo $BUCKETS | wc -w)" >> $LOGFILE
echo "Total objects : $TOTAL_OBJECTS"            >> $LOGFILE

echo ""
echo "Log saved to: $LOGFILE"