import boto3
import json
import os
from datetime import datetime, timezone
from botocore.exceptions import ClientError

# Scans S3, EC2, IAM

REGION = 'us-east-1'
REPORT_DIR = os.path.expanduser("~/Desktop/Cloud/aws-cloud-journey/02-independent-practice/aws-boto3-python")
TIMESTAMP = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
REPORT_FILE = f"{REPORT_DIR}/aws_report_{TIMESTAMP}.json"

# Clients
s3_client = boto3.client('s3', region_name=REGION)
ec2_client = boto3.client('ec2', region_name=REGION)
iam_client = boto3.client('iam')

# Helpers
def log(msg):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"    [{ts}] {msg}")

def section(title):
    print(f"\n{'-' * 25}")
    print(f"  {title}")
    print(f"{'-' * 25}")

def get_tag(tags, key):
    for tag in (tags or []):
        if tag['Key'] == key:
            return tag['Value']
    return None


# S3 Scan
def scan_s3():
    section("S3 Buckets")
    report = []

    try:
        response = s3_client.list_buckets()
        buckets = response.get('buckets', [])
        log(f"Found {len(buckets)} bucket(s)")

        for bucket in buckets:
            name = bucket['Name']
            data = {'name': name, 'issues': []}

            # Regions
            loc = s3_client.get_bucket_location(Bucket=name)
            data['region'] = loc['LocationConstraint'] or 'us-east-1'

            # object count + size
            try:
                objects = s3_client.list_objects_v2(Bucket=name)
                contents = objects.get('Content', [])
                data['object_count'] = len(contents)
                data['size_kb'] = round(
                    sum(o['Size'] for o in contents) / 1024, 2
                )

            except ClientError:
                data['object_count'] = 0
                data['size_kb'] = 0

            # Versioning
            try:
                ver = s3_client.get_bucket_versioning(Bucket=name)
                data['versioning'] = ver.get('Status', 'Disabled')
            except ClientError:
                data['versioning'] = 'Unknown'

            if data['versioning'] != 'Enabled':
                data['issues'].append('Versioning not enabled')

            
            # Encryption
            try:
                enc = s3_client.get_bucket_encryption(Bucket=name)
                rules = enc['ServerSideEncryptionConfiguration']['Rules']
                data['encryption'] = rules[0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']

            except ClientError:
                data['encryption'] = 'None'
                data['issues'].append('No Default encryption')


            # Public Access
            try:
                pub = s3_client.get_public_access_block(Bucket=name)
                cfg = pub['PublicAccessBlockConfiguration']
                data['public_blocked'] = all([
                    cfg.get('BlockPublicAcls',       False),
                    cfg.get('IgnorePublicAcls',       False),
                    cfg.get('BlockPublicPolicy',      False),
                    cfg.get('RestrictPublicBuckets',  False),
                ])
            except ClientError:
                data['public_blocked'] = False
                data['issues'].append('Public Access not fully blocked')


            # Security Score
            data['score'] = sum([
                data['versioning'] == 'Enabled',
                data['encryption'] != 'None',
                data['public_block'] == True,
            ])

            print(f"\n Bucket: {name}")
            print(f"   Region: {data['region']}")
            print(f"   Objects: {data['object_count']} ({data['size_kb']} KB)")
            print(f"   Score: {data['score']}/3")
            if data['issues']:
                for issue in data['issues']:
                    print(f"    {issue}")
                

            report.append(data)
        
    except ClientError as e:
        log(f"S3 scan error: {e.response['Error']['Message']}")

    return report



# EC2 Scan
def scan_ec2():
    section("EC2 Instances")
    report = []


    try:
        all_regions = ec2_client.describe_regions()['Regions']
        log(f"Scanning {len(all_regions)} region(s)..")

        for region in all_regions:
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

                if not instances:
                    continue

                print(f"\n Region: {region_name}")
                for i in instances:
                    name = get_tag(i.get('Tags'), 'Name') or 'No Name'
                    state = i['State']['Name']
                    ip = i.get('PublicIpAddress', 'NO IP')

                    data = {
                        'id':            i['InstanceId'],
                        'name':          name,
                        'type':          i['InstanceType'],
                        'state':         state,
                        'region':        region_name,
                        'ip':            ip,
                        'launched':      i['LaunchTime'].strftime('%Y-%m-%d'),
                        'issues':        []
                    }


                    if name == 'No Name':
                        data['issues'].append('No Name tag')

                    if state == 'stopped':
                        data['issues'].append('Instance is stopped')

                    print(f"    {i['InstanceId']} | {name} | {i['InstanceType']} | {state} | {ip}")
                    if data['issues']:
                        for issue in data['issues']:
                            print(f"    ⚠  {issue}")

                    report.append(data)

            except ClientError:
                continue
    except ClientError as e:
        log(f"EC2 scan error: {e.response['Error']['Message']}")

    if not report:
        log("NO EC2 instances found across all regions")

    return report


# IAM Scan
def scan_iam():
    section("IAM")
    report = {
        'users': [],
        'groups': [],
        'roles': [],
        'policies': []
    }

    # User
    try:

        users = iam_client.list_users()['Users']
        log(f"Found {len(users)} user(s)")

        for user in users:
            username = user['UserName']
            data = {
                'username': username,
                'created': user['CreationDate'].strftime('%Y-%m-%d'),
                'last_login': user.get('PasswordLastUsed', None),
                'issues': []
            }

            # Format last Login
            if data['last_login']:
                data['last_login'] = data['last_login'].strftime('%Y-%m-%d')
            else:
                data['last_login'] = "Never"
                data['issues'].append('Password never used')

                # MFA Check
                mfa = iam_client.list_mfa_devices(UserName=username)
                data['mfa'] = len(mfa['MFADevices']) > 0
                if not data['mfa']:
                    data['issues'].append('No MFA Found or Enabled')

                keys = iam_client.list_access_keys(UserName=username)
                data['access_keys'] = []
                for key in keys['AccessKeyMetadata']:
                    created = key['CreationDate']
                    now = datetime.now(timezone.utc)
                    age_days = (now - created).days
                    key_data = {
                        'id': key['AccessKeyId'],
                        'status': key['Status'],
                        'age_days': age_days
                    }

                    if key['Status'] == 'Active' and age_days > 90:
                        data['issues'].append(f"Access key {key['AccessKeyId']} is {age_days} days old")
                    data['access_keys'].append[key_data]

                    # Admin check via groups
                    groups = iam_client.list_groups_for_user(UserName=username)['Groups']
                    data['groups'] = [g['GroupName'] for g in groups]
                    for group in data['groups']:
                        group_policies = iam_client.list_attached_group_policies(
                            GroupName=group
                        )['AttachedPolicies']
                        for policy in group_policies:
                            if policy['PolicyName'] == 'AdminstratorAccess':
                                data['issues'].append(f'Admin access via group: {group}')

                    print(f"\n  User    : {username}")
                    print(f"  Created : {data['created']}")
                    print(f"  MFA     : {'Yes' if data['mfa'] else 'No'}")
                    print(f"  Groups  : {', '.join(data['groups']) or 'None'}")
                    print(f"  Login   : {data['last_login']}")
                    if data['issues']:
                        for issue in data['issues']:
                            print(f"  ⚠  {issue}")

                    report['users'].append(data)

    except ClientError as e:
        log(f"IAM user scan error: {e.response['Error']['Message']}")


    # Groups
    try:
        groups = iam_client.list_groups()['Groups']
        log(f"Found {len(groups)} group(s)")
        for group in groups:
            members = iam_client.get_group(GroupName=group['GroupName'])
            report['groups'].append({
                'name': group['GroupName'],
                'member_count': len(members['Users'])
            })

            print(f"\n Group: {group['GroupName']} ({len(members['Users'])} member(s)")
    except ClientError as e:
        log(f"IAM group scan error: {e.response['Error']['Message']}")


    try:
        roles = iam_client.list_roles()['Roles']
        custom_roles = [
            r for r in roles
            if not r['Path'].startswith('/aws-service-role')
        ]
        log(f"found {len(custom_roles)} custom role(s)")
        for role in custom_roles:
            report['roles'].append({'name': role['RoleName']})
            print(f"\n Role : {role['RoleName']}")
    except ClientError as e:
        log(f"IAM role scan error: {e.response['Error']['Message']}")


    try:
        policies = iam_client.list_policies(Scope='Local')['Policies']
        log(f"Found {len(policies)} customer policy/policies")
        for policy in policies:
            report['policies'].append({'name': policy['PolicyName']})
            print(f"\n Policy: {policy['PolicyName']}")
    except ClientError as e:
        log(f"IAM policy scan error: {e.response['Error']['Message']}")

    return report


# SAVE report
def save_report(data):
    section("Saving Report")

    try:
        with open(REPORT_FILE, 'w') as f:
            json.dum(data, f, indent=2, default=str)
        log(f"Report saved: {REPORT_FILE}")
    except Exception  as e:
        log(f"Error saving report: {e}")
    

