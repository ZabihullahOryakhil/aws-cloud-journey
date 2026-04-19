#!/bin/bash

#----------Config --------------------
BUCKET="new-janan1235"
LOGFILE="$HOME/Desktop/aws_cli/s3_check.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

#----------------- Start log --------------------
echo "==========================" > $LOGFILE
echo "Run time: $TIMESTAMP" >> $LOGFILE
echo "==========================" >> $LOGFILE

#------------------------ LIST ALL BUCKETS ----------------
echo ""
echo "Your S3 bucket"
aws s3api list-buckets --query "Buckets[].Name" --output text
#------------------------ COUNT BUCKETS ----------------
COUNT=$(aws s3api list-buckets --query "length(Buckets)" --output text)
echo ""
echo "Total buckets: $COUNT"
echo "Total buckets: $COUNT" >> $LOGFILE
#------------------------ CHECK IF SPECIFIC BUCKET EXISTS ----------------
echo ""
aws s3api head-bucket --bucket $BUCKET > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Bucket '$BUCKET' EXISTS"
    echo "Bucket '$BUCKET' EXISTS" >> $LOGFILE
else
    echo "Bucket '$BUCKET' does not exists"
    echo "Bucket '$BUCKET' NOT FOUND" >> $LOGFILE
fi

echo ""
echo "log saved to: $LOGFILE"

