import boto3
import os
import json
from datetime import datetime
from botocore.exceptions import ClientError

# S3 Manager - create, delete, upload, download, list_buckets, list_objects, bucket_info

s3 = boto3.client('s3', region_name='us-east-1')
REGION = 'us-east-1'


# Helper
def log(msg):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"    [{ts} {msg}]")


# FUNCTION 1 - list all buckets
def list_buckets():
    try:
        response = s3.list_buckets()
        buckets = response.get('Buckets', [])

        if not buckets:
            log("No buckets found")
            return []
        
        log(f"Found {len(buckets)} bucket(s):")
        for b in buckets:
            print(f"    {b['Name']}  |  created {b['CreationDate'].strftime('%Y-%m-%d')}")
        return buckets
    except ClientError as e:
        log(f"Error listing buckets: {e.response['Error']['Message']}")
        return []
    

# FUNCTION 2 - Create bucket
def create_bucket(bucket_name):
    try:
        if REGION == 'us-east-1':
            s3.create_bucket(Bucket=bucket_name)
        else:
            s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={'LocationConstraint': REGION}

            )
        log(f"Bucket Created: {bucket_name}")
        return True

    except ClientError as e:
        code = e.response['Error']['Code']
        if code == 'BucketAlreadyOwnedByYou':
            log(f"Bucket already exists and is yours: {bucket_name}")
            return True
        elif code == 'BucketAlreadyExists':
            log(f"Bucket name taken Globally: {bucket_name}")
            return True
        else:
            log(f"Error creating bucket: {e.response['Error']['Message']}")
            return False
        

# FUNCTION 3 - delete bucket
def delete_bucket(bucket_name, force=False):
    try:
        if force:
            log(f"Emptying bucket: {bucket_name}")
            objects = s3.list_objects_v2(Bucket=bucket_name)

            if objects.get('KeyCount', 0) > 0:
                delete_list = [{'Key': obj['Key']} for obj in objects ['Contents']]
                s3.delete_objects(
                    Bucket=bucket_name,
                    Delete={'Objects': delete_list}
                )
                log(f"Deleted {len(delete_list)} object(s)")
        s3.delete_bucket(Bucket=bucket_name)
        log(f"Bucket Deleted: {bucket_name}")
        return True
    except ClientError as e:
        log(f"Error deleting bucket: {e.response['Error']['Message']}")
        return False