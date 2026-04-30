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
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
S3_BUCKET="new-janan1234"

log() { echo "  $1"; echo "[$1]" >> $LOGFILE; }

echo "IAM Full Report — $TIMESTAMP" | tee $REPORT_FILE
echo "" | tee -a $REPORT_FILE

# TODO 1: List all users with creation date
echo "--- USERS ---" | tee -a $REPORT_FILE

USERS=$(aws iam list-users | jq -r '.Users[] | .UserName + " | Created: " + .CreateDate')


# TODO 2: List all groups and users count per group
echo "" | tee -a $REPORT_FILE
echo "=== GROUPS ===" | tee -a $REPORT_FILE

GROUP_NAMES=$(aws iam list-groups | jq -r '.Groups[].GroupName')

for GROUP in $GROUP_NAMES; do
    USER_COUNT=$(aws iam list-group --group-name $GROUP | jq '.Users | length')

    echo "Group: $Group | Users: $USER_COUNT" | tee -a $REPORT_FILE
done


# TODO 3: list customer-managed policies only
echo "" | tee -a $REPORT_FILE
echo "=== CUSTOMER POLICIES ===" | tee -a $REPORT_FILE

POLICIES=$(aws iam list-policies --scope local | jq -r '.Policies[] | .PolicyName + " | Last Updated: " + .UpdatedDate' | tee -a $REPORT_FILE)

