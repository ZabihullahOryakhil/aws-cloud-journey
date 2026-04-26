#!/bin/bash

# IAM Auditor
# Checks: users, admin access, MFA, old access keys

# Config
LOGFILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/iam-audit.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
KEY_AGE_LIMIT=90
ISSUES=0


# Log Function
log () {
    local TS=$(date "+%Y-%m-%d %H:%M:%S")
    echo "  $1"
    echo "[$TS] $1" >> $LOGFILE
}

warning() {
    echo "Warning: $1"
    echo "[WARNING] $1" >> $LOGFILE
    ISSUES=$((ISSUES + 1))
}

ok() {
    echo " ✓ $1"
    echo "[OK] $1" >> $LOGFILE
}

# Starting Prints
echo ""
echo "------------------------"
echo "IAM Security Auditor"
echo "$TIMESTAMP"
echo "------------------------"
echo ""

echo "IAM Audit Report" > $LOGFILE
echo "RunTime: $TIMESTAMP" >> $LOGFILE
echo "-------------------------"

# Fetching all users
log "Fetching all IAM Users..."
echo ""

USER_JSON=$(aws iam list-users 2>&1)

if [ $? -ne 0 ]; then
    log "Error: Could not fetch IAM Users"
    exit 1
fi

USER_COUNT=$(echo "$USER_JSON" | jq '.Users | length')
log "Found $USER_COUNT IAM User(s)"

# Loop through each user
for USERNAME in $(echo "$USER_JSON" | jq -r '.Users[].UserName'); do

    echo "--------------------"
    echo "User: $USERNAME"
    echo "" >> $LOGFILE
    echo "User: $USERNAME" >> $LOGFILE
    echo "--------------------" >> $LOGFILE


    # Check admin access
    POLICIES=$(aws iam list-attached-user-policies \
        --user-name $USERNAME \
        --query "AttachedPolicies[].PolicyName" \
        --output text 2>/dev/null)

    GROUPS=$(aws iam list-groups-for-user \
        --user-name $USERNAME \
        --query "Groups[].GroupName" \
        --output text 2>/dev/null)

    if echo "$POLICIES" | grep -qi "AdministratorAccess"; then
        warning "$USERNAME has AdministratorAccess policy attached directly"
    else
        ok "$USERNAME - no direct admin policy"
    fi

    # Check for MFA enabled
    MFA=$(aws iam list-mfa-devices \
        --user-name $USERNAME \
        2>/dev/null | jq '.MFADevices | length')

    if [ "$MFA" -eq 0 ]; then
        warning "$USERNAME has NO MFA device enabled"
    else
        ok "$USERNAME - MFA enabled ($MFA device)"
    fi

    # Check for Access key age
    KEY_JSON=$(aws iam list-access-keys \
        --user-name $USERNAME 2>/dev/null)

    KEY_COUNT=$(echo $KEY_JSON | jq -r '.AccessKeyMetadata | length')

    if [ $KEY_COUNT -eq 0 ]; then
        ok "$USERNAME - no access key "
    else
        for KEY_ID in $(echo "$KEY_JSON" | jq -r '.AccessKeyMetadata[].AccessKeyId'); do

            # getting the key status and creation date
            KEY_STATUS=$(echo "$KEY_JSON" | jq -r \
                --arg kid "$KEY_ID" \
                '.AccessKeyMetadata[] | select(.AccessKeyId==$kid) | .Status')
            KEY_DATE=$(echo "$KEY_JSON" | jq -r \
                --arg kid "$KEY_ID" \
                '.AccessKeyMetadata[] | select(.AccessKeyId==$kid) | .CreateDate')


            # calculation of age in days
            KEY_EPOCH=$(date -d "$KEY_DATE" +%s 2>/dev/null)
            NOW_EPOCH=$(date +%s)
            AGE_DAYS=$(( (NOW_EPOCH - KEY_EPOCH) / 86400 ))

            if [ "$KEY_STATUS" == "Active" ] && [ "$AGE_DAYS" -gt "$KEY_AGE_LIMIT" ]; then
                warning "$USERNAME - access key is $AGE_DAYS days old (limit: $KEY_AGE_LIMIT days)"
            else
                ok "$USERNAME - key $KEY_ID is $AGE_DAYS days old, status: $KEY_STATUS"
            fi 
        done
    fi

    # 4- Checking for last use of the password
    LAST_USED=$(echo "$USER_JSON" | jq -r \
        --arg u "$USERNAME" \
        '.Users[] | select(.UserName==$u) | .PasswordLastUsed // "never"')

    if [ "$LAST_USED" == "never" ]; then
        warning "$USERNAME - password has never been used (Possible inactive user, maybe you check out)"
    else
        ok "$USERNAME - last login: $LAST_USED"
    fi

    echo ""
done

# Final summary
echo "AUDIT SUMMARY"
echo "Total Users: $USER_COUNT"
echo "Total issues: $ISSUES"

if [ "$ISSUES" -eq 0 ]; then
    echo "  Result : ALL CLEAR"
else
    echo "  Result : $ISSUES ISSUE(s) Found -review log"
fi
echo "" >> $LOGFILE
echo "SUMMARY"                         >> $LOGFILE
echo "Total users  : $USER_COUNT"      >> $LOGFILE
echo "Total issues : $ISSUES"          >> $LOGFILE