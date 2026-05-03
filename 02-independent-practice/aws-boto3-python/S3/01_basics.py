import boto3
import json
from datetime import datetime

# Connect to S3
s3 = boto3.client('s3', region_name='us-east-1')

# Listing buckets
print("-" * 20)
print("All S3 buckets")
print("-" * 20)

response = s3.list_buckets()

# Response is a python dict - same as json from CLI
buckets = response['Buckets']

print(f"Total buckets: {len(buckets)}")

for bucket in buckets:
    name = bucket['name']
    created = bucket['CreationDate']
    print(f"    Bucket: {name}")
    print(f"    Created: {created}")
    print(f" -------")

# Creating A bucket
print("")
print("-" * 20)
print("Creating a new bucket")
print("-" * 20)

BUCKET_NAME = "new-janan1235"

try:
    s3.create_bucket(bucket=BUCKET_NAME)
    print(f"    Created: {BUCKET_NAME}")
except s3.exceptions.BucketAlreadyOwnedByYou:
    print(f"    already exists: {BUCKET_NAME}")
except Exception as e:
    print(f"    Error: {e}")


# Uplaoding a file
print("")
print("-" * 20)
print("Uploading a file")
print("-" * 20)

with open("/tmp/boto3_test.txt", "w") as f:
    f.write(f"Hello from boto3\nTimestamp: {datetime.now()}")

try:
    s3.upload_file(
        Filename="tmp/boto3_test.txt"
        Bucket=BUCKET_NAME
        key="test/boto3_test.txt"
    )
    print(f"    Uploaded boto3_test.txt -> s3://{BUCKET_NAME}/test/")
except Exception as e:
    print(f"    Upload Error: {e}")

# List objects in bucket
print("")
print("-" * 20)
print(f"Objects in {BUCKET_NAME}")
print("-" * 20)

try:
    objects: s3.list_objects_v2(Bucket=BUCKET_NAME)

    if objects['KeyCount'] == 0:
        print(" Empty bucket")
    else:
        for obj in objects['Contents']:
            print(f"    File: {obj['Key']}")
            print(f"    Size: {obj['Size']} bytes")
            print("------")

except Exception as e:
    print(f"    Error: {e}")
    