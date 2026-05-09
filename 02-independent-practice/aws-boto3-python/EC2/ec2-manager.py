import boto3
import time
from datetime import datetime
from botocore.exceptions import ClientError

ec2 = boto3.client('ec2', region_name='us-east-1')
REGION = 'us-east-1'

# Helper
def log(msg):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"  [{ts}] {msg}")


def get_instance_name(instance):
    tags = instance.get('Tags', [])
    for tag in tags:
        if tag['Key'] == 'Name':
            return tag['Value']
    return 'No Name'


# FUNCTION 1 - list all instances
def list_instances(state_filter=None):
    try:
        filters = []
        if state_filter:
            filters.append({
                'Name': 'instance-state-name',
                'Values': [state_filter]
            })

            response = ec2.describe_instances(Filters=filters)

            instances = []
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    instances.append(instance)

            if not instances:
                log(f"No instances found" + (f" with state: {state_filter}" if state_filter else ""))
                return []
        
            log(f"Found {len(instances)} instance(s):")
            print("")
            for i in instances:
                name    =get_instance_name(i)
                state   =i['State']['Name']
                ip      =i.get('PublicIpAddress', 'No IP')
                launched = i['LaunchTime'].strftime('%Y-%m-%d')

                print(f"    ID      : {i['InstanceId']}")
                print(f"    Name    : {name}")
                print(f"    Type    : {i['InstanceType']}")
                print(f"    State   : {state}")
                print(f"    IP      : {ip}")
                print(f"    Launched: {launched}")
                print(f"    --------")

            return instances
    except ClientError as e:
        log(f"Error: {e.response['Error']['Message']}")
        return []
    
# FUNCTION 2 = get single instance details
def get_instance(instance_id):
    try:
        response=ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        return instance


    except ClientError as e:
        code = e.response['Error']['Code']
        if code == 'InvalidInstanceID.NotFound':
            log(f"Instance not found: {instance_id}")
        else:
            log(f"Error: {e.response['Error']['Message']}")
        return None
    

# FUNCTION 3 = Stop instnace
def stop_instance(instance_id, wait=True):
    instance = get_instance(instance_id)
    if not instance:
        return False
    
    state = instance['State']['Name']

    if state == 'stopped':
        log(f"Already stopped: {instance_id}")
        return True
    
    if state == 'terminated':
        log(f"Instance is terminated — cannot stop: {instance_id}")
        return False
    
    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        log(f"Stop command sent: {instance_id}")

        if wait:
            log("Waiting for instance to stop...")
            waiter = ec2.get_waiter('instance_stopped')
            waiter.wait(InstanceIds=[instance_id])
            log(f"Instance stopped: {instance_id}")

        return True
    
    except ClientError as e:
        log(f"Error stopping: {e.response['Error']['Message']}")
        return False
    
# FUNCTION 4 - Start instance
def start_instance(instance_id, wait=True):
    instance = get_instance(instance_id)
    if not instance:
        return False
    state = instance['State']['Name']

    if state == 'running':
        log(f"Already running: {instance_id}")
        return True
    
    if state == 'terminated':
        log(f"Instance is terminated - cannot start: {instance_id}")
        return False
    
    try:
        ec2.start_instances(InstanceIds=[instance_id])
        log(f"Start command sent: {instance_id}")

        if wait:
            log("Waiting for instance to be running...")
            waiter = ec2.get_waiter("instance_running")
            waiter.wait(InstanceIds=[instance_id])

            # getting the new IP after start
            updated = get_instance(instance_id)
            new_ip = updated.get('PublicIpAddress', 'No IP')
            log(f"Instance running: {instance_id}")
            log(f"New public IP: {new_ip}")


        return True
    except ClientError as e:
        log(f"Error starting: {e.response['Error']['Message']}")
        return False
    
# FUNCTION 5 - Terminate instance
def terminate_instance(instance_id):
    instance = get_instance(instance_id)
    if not instance:
        return False
    
    state = instance['State']['Name']
    name = get_instance_name(instance)

    if state == 'terminated':
        log(f"Already terminated: {instance_id}")
        return True
    
    print(f"\n  WARNING: This will PERMANENTLY delete:")
    print(f"  Name : {name}")
    print(f"  ID   : {instance_id}")
    confirm = input("\n  Type the instance ID to confirm: ").strip()

    if confirm != instance_id:
        log("Termination cancelled - ID did not match")
        return False
    
    try:
        ec2.terminate_instances(InstanceIds=[instance_id])
        log(f"Terminate command sent: {instance_id}")

        log("waiting for termination...")
        waiter = ec2.get_waiter('instance_terminated')
        waiter.wait(InstanceIds=[instance_id])
        log(f"Instance terminated: {instance_id}")
        return True
    
    except ClientError as e:
        log(f"Error terminating: {e.response['Error']['Message']}")
        return False
    

# FUNCTION 6 - Create instance
def create_instance(name, instance_type='t2.micro', ami_id=None):
    # Get latest amazon linux 2 AMI if none provided
    if ami_id is None:
        try:
            images = ec2.describe_images(
                Owners=['amazon'],
                Filters=[
                    {'Name': 'name',         'Values': ['amzn2-ami-hvm-*-x86_64-gp2']},
                    {'Name': 'state',        'Values': ['available']},
                    {'Name': 'architecture', 'Values': ['x86_64']}
                ]
            )

            # sort by creation date and get latest
            sorted_images = sorted(
                images['Images'],
                key=lambda x: x['CreationDate'],
                reverse=True
            )

            ami_id = sorted_images[0]['ImageId']
            log(f"Using latest AMI: {ami_id}")

        except ClientError as e:
            log(f"Error getting AMI: {e.response['Error']['Message']}")
            return None
    
    try:
        response = ec2.run_instances(
            ImageId=ami_id,
            InstanceType=instance_type,
            MinCount=1,
            MaxCount=1,
            TagSpecifications=[{
                'ResourceType': 'instance',
                'Tags': [{'Key': 'Name', 'Value': name}]
            }]
        )

        instance_id = response['Instances'][0]['InstanceId']
        log(f"Instance created: {instance_id}")
        log(f"Waiting for instance to be running")

        waiter = ec2.get_waiter('instance_running')
        waiter.wait(InstanceIds=[instance_id])

        instance = get_instance(instance_id)
        ip = instance.get('PublicIpAddress', 'No IP')
        log(f"Instance running: {instance_id}")
        log(f"Public IP: {ip}")

        return instance_id
    
    except ClientError as e:
        log(f"error creating instance: {e.response['Error']['Message']}")
        return None
    


# FUNCTION 7 - Multi Region Scan
def scan_all_regions():
    log("Scanning all regions for EC2 Instance..")
    print("")

    all_region = ec2.describe_regions()['Regions']
    total = 0

    for region in all_region:
        region_name = region['RegionName']
        regional_ec2 = boto3.client('ec2', region_name=region_name)

        try:
            response = regional_ec2.describe_instances()
            instances = [
                i
                for r in response['Reservations']
                for i in r['Instances']
                if i['State']['Name'] != 'terminated'
            ]

            if instances:
                print(f"  Region: {region_name} — {len(instances)} instance(s)")
                for i in instances:
                    name  = get_instance_name(i)
                    state = i['State']['Name']
                    print(f"    {i['InstanceId']} | {name} | {i['InstanceType']} | {state}")
                total += len(instances)
            else:
                print(f"  Region: {region_name} — no instances")

        except ClientError:
            print(f"  Region: {region_name} — access denied or unavailable")

    print("")
    log(f"Total active instances across all regions: {total}")

# MAIN

if __name__ == "__main__":
    print("\n" + "=" * 45)
    print("  EC2 Manager — boto3")
    print("=" * 45 + "\n")

    # 1. List all instances
    log("Listing all instances...")
    list_instances()
    print("")

    # 2. List only running instances
    log("Listing running instances only...")
    list_instances(state_filter='running')
    print("")

    # 3. Scan all regions
    scan_all_regions()
    print("")