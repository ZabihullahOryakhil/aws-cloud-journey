#!/bin/bash


# ═══════════════════════════════════════════════════
# Challenge 3 — IAM Full Report + Upload to S3
#
# What it should do:
# 1. List all IAM users with creation date
# 2. List all IAM groups and how many users in each
# 3. List all IAM roles (not users — roles are different)
# 4. List all customer-managed policies (not AWS managed)
# 5. Check which users have console access (login profile)
# 6. Check which users have programmatic access (access keys)
# 7. Save the full report as a .txt file
# 8. Upload that report file to an S3 bucket you choose
# 9. Verify the upload succeeded

REPORT_FILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/iam_full_report.txt"
LOGFILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/challenge3.log"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
S3_BUCKET="new-janan1234"

log() { echo "  $1"; echo "[$1]" >> $LOGFILE; }

echo "IAM Full Report — $TIMESTAMP" | tee $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# TODO 1: List all users with creation date
echo "--- USERS ---" | tee -a $REPORT_FILE

aws iam list-users | jq -r '.Users[] | .UserName + " | Created: " + .CreateDate' | tee -a $REPORT_FILE


# TODO 2: List all groups and users count per group
echo "" | tee -a $REPORT_FILE
echo "=== GROUPS ===" | tee -a $REPORT_FILE

GROUP_NAMES=$(aws iam list-groups | jq -r '.Groups[].GroupName')

for GROUP in $GROUP_NAMES; do
    USER_COUNT=$(aws iam get-group --group-name $GROUP | jq '.Users | length')

    echo "Group: $GROUP | Users: $USER_COUNT" | tee -a $REPORT_FILE
done


# TODO 3: list customer-managed policies only
echo "" | tee -a $REPORT_FILE
echo "=== CUSTOMER POLICIES ===" | tee -a $REPORT_FILE

aws iam list-policies --scope Local | jq -r '.Policies[] | .PolicyName + " | Last Updated: " + .UpdateDate' | tee -a $REPORT_FILE

# TODO 4: IAM role listing
echo "" | tee -a $REPORT_FILE
echo "=== ROLES ===" | tee -a $REPORT_FILE
aws iam list-roles | jq -r '.Roles[] | 
    select(.Path | startswith("/aws-service-role") | not) |
    .RoleName + " | created: " + .CreateDate' | tee -a $REPORT_FILE

# TODO 5 + 6: for each user check console and programmatic access
echo "" | tee -a $REPORT_FILE
echo "=== ACCESS TYPE PER USER ===" | tee -a $REPORT_FILE

#   getting all usernames
USER_NAMES=$(aws iam list-users | jq -r '.Users[].UserName')

for USER  in $USER_NAMES; do
    # Check for console access
    HAS_CONSOLE=$(aws iam get-login-profile --user-name $USER 2>/dev/null | jq -r '.LoginProfile.UserName' )
    if [ "$HAS_CONSOLE" != "NULL" ] && [ -n "$HAS_CONSOLE" ]; then
        CONSOLE="Console: YES"
    else
        CONSOLE="Console: NO"

    fi

    # Check for programmatic access
    KEY_COUNT=$(aws iam list-access-keys --user-name $USER | jq '.AccessKeyMetadata | length')
    if [ "$KEY_COUNT" -gt 0 ]; then
        PROGRAM="Keys: Yes ($KEY_COUNT)"
    else
        PROGRAM="Keys: NO"
    fi

    echo "User: $USER | $CONSOLE | $PROGRAM" | tee -a $REPORT_FILE
done


# TODO 7: upload report to S3
echo "" | tee -a $REPORT_FILE
log "Uploading report to S3..."

aws s3 cp "$REPORT_FILE" "s3://$S3_BUCKET/reports/iam_report_$TIMESTAMP.txt"

if [ $? -eq 0 ]; then
    echo "Uplaoded SuccessfullY..." | tee -a $REPORT_FILE
    log "Uplaod Complete"
else
    echo "Error: Uplaoding Failed" | tee -a $REPORT_FILE
    log "Uplaod Failed."
fi