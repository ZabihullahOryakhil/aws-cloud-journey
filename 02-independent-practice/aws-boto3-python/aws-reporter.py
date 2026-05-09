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

