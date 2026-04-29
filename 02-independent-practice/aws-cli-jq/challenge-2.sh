#!/bin/bash

# Challenge 2 — EC2 Multi-Region Lister
#
# What it should do:
# 1. Get all available AWS regions dynamically
#    (not hardcoded — fetch from CLI)
# 2. Loop through every region
# 3. In each region check for EC2 instances
# 4. If instances found — print id, type, state, region
# 5. Count total instances across all regions
# 6. Flag any instances that are running but have
#    no Name tag — these are untagged resources
# 7. Save full report


# Config
LOGFILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/challenge2.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TOTAL_INSTANCES=0
UNTAGGED=0

# Log
log() { echo "  $1"; echo "[$1]" >> $LOGFILE; }
warning() { echo "  WARNING: $1"; echo "[WARNING] $1" >> $LOGFILE; }
ok() { echo "  OK: $1"; echo "[OK] $1" >> $LOGFILE; }

echo "EC2 Multi-Region Scanner - $TIMESTAMP"
echo ""


# TODO 1: get all regions dynamically
REGIONS=$(aws ec2 describe-regions \
    --query "Regions[].RegionName" \
    --output text)

for REGION in $REGIONS; do
    echo "Scanning region: $REGION"

    # TODO 2: get all instances in this region
    INSTANCES=$(aws ec2 describe-instances \
        --region "$REGION" \
        --output json)

    # TODO 3: count instances in this region
    INSTANCE_COUNT=$(echo "$INSTANCES" | jq '[.Reservations[].Instances[]] | length')

    if [ "$INSTANCE_COUNT" -eq 0 ]; then
        echo " No instances"
        continue
    fi
    TOTAL_INSTANCES=$((TOTAL_INSTANCES + INSTANCE_COUNT))
    log "Found $INSTANCE_COUNT instance in $REGION"


    echo "$INSTANCES" | jq -r '.Reservations[].Instances[] | 
        "\(.InstanceId)\t\(.InstanceType)\t\(.State.Name)\t\( (.Tags[]? | select(.key=="Name").Value) \\ "NoName")"' | \
    while read -r ISNTANCE_ID TYPE STATE NAME; do
        if [ "$NAME" == "NoName" ]; do
            UNTAGGED=$((UNTAGGED + 1))
            warning "Instances $INSTANCE_ID in $REGION has no Name tag!"
        else
            ok "Instance: $NAME ($INSTANCE_ID) | TYPE: $TYPE | State: $STATE"
        fi
    done
    
