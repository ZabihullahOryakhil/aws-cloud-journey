# ── Guard: make sure user passed a bucket name ────────
if [ $# -eq 0 ]; then
    echo "Usage: bash upgraded_script.sh <bucket-name>"
    echo "Example: bash upgraded_script.sh new-janan12345"
    exit 1
fi
# ── Config ────────────────────────────────────────────
BUCKET=$1
LOGFILE="$HOME/Desktop/aws_cli/upgraded_script.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# ── Start log ─────────────────────────────────────────
echo "=============================" >> $LOGFILE
echo "Run time : $TIMESTAMP"        >> $LOGFILE
echo "Bucket   : $BUCKET"           >> $LOGFILE
echo "=============================" >> $LOGFILE


# ── List all buckets ──────────────────────────────────
echo ""
echo "All your S3 buckets:"
aws s3api list-buckets --query "Buckets[].Name" --output text

# ── Count buckets ─────────────────────────────────────
COUNT=$(aws s3api list-buckets --query "length(Buckets)" --output text)
echo ""
echo "Total buckets: $COUNT"
echo "Total buckets: $COUNT" >> $LOGFILE

# ── Check if passed bucket exists ─────────────────────
echo ""
aws s3api head-bucket --bucket $BUCKET > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Bucket '$BUCKET' EXISTS"
    echo "Status: EXISTS" >> $LOGFILE

    # ── Count objects inside the bucket ───────────────
    OBJ_COUNT=$(aws s3 ls s3://$BUCKET --recuresive | wc -l)
    echo "Objects inside: $OBJ_COUNT"
    echo "Objects inside: $OBJ_COUNT" >> $LOGFILE

    # ── Show the files ────────────────────────────────
    echo ""
    echo "Files in '$BUCKET':"
    aws s3 ls s3://$BUCKET
else
    echo "Bucket '$BUCKET' does NOT exist"
    echo "Status: NOT FOUND" >> $LOGFILE
fi

echo ""
echo "Log saved to: $LOGFILE"
