4#!/bin/bash

LOGFILE="$HOME/Desktop/aws_cli/ec2_manager.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DRY_RUN=true   # Set to false only when you're sure

echo "=============================" >> "$LOGFILE"
echo "EC2 Manager Report" >> "$LOGFILE"
echo "Run time : $TIMESTAMP" >> "$LOGFILE"
echo "=============================" >> "$LOGFILE"

echo ""
echo "🚀 EC2 Manager started at $TIMESTAMP"
echo ""

# Helper function
print_header() {
    echo ""
    echo " $1"
    echo "-------------------------------------------"
}

# Case 1: Single Instance ID provided
if [[ $1 == i-* ]]; then
    INSTANCE_ID=$1
    print_header "Detailed info for instances $INSTANCE_ID"

    aws ec2 describe-instances --instance-ids "$INSTANCE_ID" | jq -r '.Reservations[].Instances[] | {
            InstanceId: .InstanceId,
            State: .State.Name,
            Type: .InstanceType,
            LaunchTime: .LaunchTime,
            PublicIP: (.PublicIpAddress // "None"),
            PrivateIP: .PrivateIpAddress,
            Tags: (.Tags // [] | map(.Key + "=" + .Value) | join(", "))
        }'

    echo "Details logged." >> "$LOGFILE"
    exit 0
fi

# Case 2: Special action --stop-dev
if [ "$1" = "--stop-dev" ]; then
    print_header "Finding dev instances to stop (Environment=dev or Environment=test)"

    RUNNING_DEV_INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=tag:Environment,Values=dev,test" "Name=instances-state-name,Values=running" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)
    if [ -z "$RUNNING_DEV_INSTANCES" ]; then
        echo "No running dev/test instances found."
        echo "No instances to stop." >> "$LOGFILE"
        exit 0
    fi

    echo "Found instances: $RUNNING_DEV_INSTANCES"
    echo "Instances found: $RUNNING_DEV_INSTANCES" >> "$LOGFILE"

    if [ "$DRY_RUN" = true ]; then
        echo "🛡️  DRY-RUN MODE: Would stop the following instances:"
        echo "$RUNNING_DEV_INSTANCES"
        echo ""
        echo "To actually stop them, change DRY_RUN=false in the script and run again."
        echo "Dry-run only." >> "$LOGFILE"
    else
        echo "Stopping instances now..."
        aws ec2 stop-instances --instance-ids $RUNNING_DEV_INSTANCES
        echo "Instances stopped: $RUNNING_DEV_INSTANCES" >> "$LOGFILE"
        echo "Stop command issued"
    fi
    exit 0
fi

print_header "Full EC2 Inventory (all instances)"

aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.State.Name != "terminated") | {
        InstanceId: .InstanceId,
        State: .State.Name,
        Type: .InstanceType,
        LaunchTime: (.LaunchTime | split("T")[0]),
        PublicIP: (.PublicIpAddress // "None"),
        NameTag: (.Tags[]? | select(.Key=="Name") | .Value // "NoName")
    } | "\(.InstanceId) |\t\(.State) |\t\(.Type) |\t\(.LaunchTime) |\t\(.PublicIP) |\t\(.NameTag)"' | column -t -s $'\t'


# Summary with jq
TOTAL_RUNNING=$(aws ec2 describe-instances \
    --query "Reservations[].Instances[?State.Name=='running'] | length(@)" \
    --output text)

TOTAL_INSTANCES=$(aws ec2 describe-instances \
    --query "Reservations[].Instances[?State.Name!='terminated'] | length(@)" \
    --output text)

echo ""
echo "📊 SUMMARY:"
echo "   Total non-terminated instances : $TOTAL_INSTANCES"
echo "   Currently running              : $TOTAL_RUNNING"
echo ""

echo "Summary - Running: $TOTAL_RUNNING | Total: $TOTAL_INSTANCES" >> "$LOGFILE"
echo "Full report saved to: $LOGFILE"