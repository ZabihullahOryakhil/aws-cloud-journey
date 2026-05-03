import boto3 
s3 = boto3.client('s3')
buckets = s3.list_buckets()['Buckets']
for bucket in buckets:
    print(f"Bucket: {bucket['Name']}")
    