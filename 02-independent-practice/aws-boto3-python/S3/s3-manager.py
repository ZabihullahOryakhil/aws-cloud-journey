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


# FUNCTION 4 - Upload file
def upload_file(local_path, bucket_name, key=None):
    # If no key given use the filename
    if key is None:
        key = os.path.basename(local_path)

    try:
        s3.upload_file(
            Filename=local_path,
            Bucket=bucket_name,
            Key=key
        )
        log(f"uploaded: {local_path} -> s3://{bucket_name}/{key}")
        return True
    
    except FileNotFoundError:
        log(f"Local file not found: {local_path}")
        return False
    except ClientError as e:
        log(f"Upload Error: {e.response['Error']['Message']}")
        return False


# FUNCTION 5 - Download file
def download_file(bucket_name, key, local_path=None):
    if local_path is None:
        local_path = f"/tmp/{os.paht.basename(key)}"

    try:
        s3.download_file(
            Bucket=bucket_name,
            Key=key,
            Filename=local_path
        )
        log(f"Downloaded: s3://{bucket_name}/{key} -> {local_path}")
        return local_path
    
    except ClientError as e:
        code = e.response['Error']['Code']
        if code == '404':
            log(f"File not found in s3: {key}")
        else:
            log(f"Download error: {e.response['Error']['Message']}")
        return None


# FUNCTION 6 - list objects in bucket
def list_objects(bucket_name):
    try:
        response = s3.list_objects_v2(Bucket=bucket_name)
        objects = response.get('Contents', [])

        if not objects:
            log(f"Bucket is empty: {bucket_name}")
            return []
        
        log(f"Objects in {bucket_name}:")
        for obj in objects:
            size_kb = round(obj['Size'] / 1024, 2)
            print(f"    {obj['Key']} | {size_kb} KB | {obj['Lastmodified'].strftime('%Y-%m-%d')}")
        return objects
    except ClientError as e:
        log(f"Error listing objects: {e.response['Error']['Message']}")
        return []
    

# FUNCTION 7 - Bucket Info (region, versioning, size)
def bucket_info(bucket_name):
    info = {}

    try:
        # Region
        loc = s3.get_bucket_location(Bucket=bucket_name)
        info['region'] = loc['LocationConstraint'] or 'us-east-1'

        # Versioning
        ver = s3.get_bucket_versioning(Bucket=bucket_name)
        info['versioning'] = ver.get('Status', 'Disabled')

        # Total size and count
        objects = s3.list_objects_v2(Bucket=bucket_name)
        contents = objects.get('Contents', [])
        info['object_count'] = len(contents)
        info['total_size_kb'] = round(
            sum(obj['Size'] for obj in contents) / 1024, 2
        )

        log(f"Bucket info for {bucket_name}:")
        print(f"    Region      : {info['region']}")
        print(f"    Versioning  : {info['versioning']}")
        print(f"    Objects     : {info['object_count']}")
        print(f"    Total size  : {info['total_size_kb']} KB")

        return info
    
    except ClientError as e:
        log(f"Error listing objects: {e.response['Error']['Message']}")
        return []