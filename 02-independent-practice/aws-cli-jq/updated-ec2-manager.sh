#!/bin/bash

# EC2 Manager
# Usage: updated-ec2-manager.sh <<action>> [instance-id]
# Actions: list, start, stop, status, terminate
# -----------------------------------------------------------

# Config
REGION="us-east-1"
LOGFILE="$HOME/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-cli-jq/updated_ec2_manager.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# --- Log Function --------
log () {
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo " $1"
    echo "[$TIMESTAMP] $1" >> $LOGFILE
}

# Guard
if [ $# -eq 0 ]; then
    echo ""
    echo "  Usage: bash ec2_manager.sh <action> [instance-id]"
    echo ""
    echo "  Actions:"
    echo "  list -> List all instances"
    echo "  status <id>"
    echo "  stop <id>"
    echo "  start <id>"
    echo " terminate <id>"
    echo ""
    exit 1
fi

ACTION=$1
INSTANCE_ID=$2

echo ""
echo "  EC2 Manager | $ACTION"
echo "  $TIMESTAMP"
echo ""

# 1- Action: List

if [ "$ACTION" == "list" ]; then
    log "Fetcing all EC2 instances in $REGION..."
    echo ""

    RESULT=$(aws ec2 describe-instances \
        --region $REGION \
        --query "Reservations[].Instances[]" 2>&1)

    if [ $? -ne 0 ]; then
        log "Error: Could not fetch instances"
        exit 1
    fi

    COUNT=$(echo $RESULT | jq 'length')

    if [ "$COUNT" -eq 0 ]; then
        log "No instances found in $REGION"
        exit 0
    fi

    log "Found $COUNT Instance(s):"
    echo ""

    echo $RESULT | jq -r '.[] |
        "   ID  : " + .InstanceId +
        "\n     Name    : " + (.Tags[]? | select(.Key=="Name") | .Value) +
        "\n     Type    : " + .InstanceType +
        "\n     State   : " + .State.Name +
        "\n     IP      : " + (.PublicIpAddress // "no public IP") +
        "\n     -----------------------------"'

    echo ""
    log "Total Instances: $COUNT"

# 2- Action: status
elif [ "$ACTION" == "status" ]; then
    if [ -z "$INSTANCE_ID" ]; then
        echo " Error: provide an instance ID"
        echo "Usage: updated-ec2-manager.sh status i-xxxxxxxxxxxxx"
        exit 1
    fi

    log "Checking status of $INSTANCE_ID..."
    STATE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text 2>&1)

    if [ $? -ne 0 ]; then
        echo "Error: Instance $INSTANCE_ID not found"
        exit 1
    fi

    IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)

    TYPE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query "Reservations[0].Instances[0].InstanceType" \
        --output text)

    echo "  Instance : $INSTANCE_ID"
    echo "  Type     : $TYPE"
    echo "  State    : $STATE"
    echo "  IP       : $IP"
    echo ""
    log "Status check: $INSTANCE_ID -> $STATE"

# 3- Action: Stop a running instance
elif [ "$ACTION" == "stop" ]; then
    if [ -z "$INSTANCE_ID" ]; then
        echo "Error: provide and instance ID"
        echo "Usage: updated-ec2-manager.sh stop i-xxxxxxxxxxxxx"
    exit 1
    fi

    STATE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text 2>&1)


    # Check current status
    if [ "$STATE" == "stopped" ]; then
        echo "Instance $INSTANCE_ID is already stopped"
        exit 0
    fi

    # Check current status
    if [ "$STATE" == "terminated" ]; then
        log "ERROR: Instance $INSTANCE_ID is terminated — cannot stop"
        exit 1
    fi

    log "Stopping instance $INSTANCE_ID (CurrentState: $STATE)..."

    aws ec2 stop-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log "Stop command sent successfully"
        log "Waiting for instance to stop..."

        aws ec2 wait instance-stopped \
        --instance-ids $INSTANCE_ID \
        --region $REGION

        log "Instance $INSTANCE_ID is now Stopped"
    else
        log "Error: Could not stop the instance $INSTANCE_ID"
        exit 1
    fi

# 4- Action: Start a stopped instance
elif [ "$ACTION" == "start" ]; then
    if [ -z "$INSTANCE_ID" ]; then
        echo "  ERROR: provide an instance ID"
        echo "  Usage: updated-ec2-manager.sh start i-xxxxxxxxxxx"
        exit 1
    fi

    STATE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text 2>&1)

    if [ "$STATE" == "running" ]; then
        log "Instance $INSTANCE_ID is already running"
        exit 0
    fi

    if [ "$STATE" == "terminated" ]; then
        log "Error: Instance $INSTANCE_ID is terminated -> sorry cannot start"
        exit 1
    fi
    

    log "Starting instance $INSTANCE_ID (current: $STATE)..."

    aws ec2 start-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log "Start command sent successfully"
        log "Waiting for instance to be running.."

        aws ec2 wait instance-running \
            --instance-ids $INSTANCE_ID \
            --region $REGION

        
        NEW_IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)

            log "Instance $INSTANCE_ID is now Running"
            log "NEW Public IP: $NEW_IP"

    else
        log "Error: Could not start instance $INSTANCE_ID"
        exit 1
    fi


# 5- Action: Terminate (permanently delete an instance)
elif [ "$ACTION" == "terminate" ]; then
    if [ -z "$INSTANCE_ID" ]; then
        echo "  ERROR: provide an instance ID"
        echo "  Usage: updated-ec2-manager.sh terminate i-xxxxxxxxxxx"
        exit 1
    fi

    # Safety
    echo "  WARNING: This will PERMANENTLY delete $INSTANCE_ID"
    echo "  Type the instance ID to confirm: "
    read CONFIRM

    if [ "$CONFIRM" != "$INSTANCE_ID" ]; then
        log "Termination cancelled — ID did not match"
        exit 0
    fi

    log "Terminating instance $INSTANCE_ID..."

    aws ec2 terminate-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION > /dev/null 2>&1


    if [ $? -eq 0 ]; then
        log "Terminate command sent"
        log "waiting for termination"

        aws ec2 wait instance-terminated \
            --instnace-ids $INSTANCE_ID \
            --region $REGION

        log "Instance $INSTANCE_ID is Terminated"

    else
        log "Error: Could not terminate instance $INSTANCE_ID"
        exit 1
    fi
else
    echo "  ERROR: unknown action '$ACTION'"
    echo "  Run script with no arguments to see usage"
    exit 1
fi

echo ""
echo " Log Saved to: $LOGFILE"
echo ""
