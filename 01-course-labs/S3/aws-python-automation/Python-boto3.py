import boto3
import os

# bucketName = input("Please Enter the bucket Name: ")

# Creating S3 client
s3 = boto3.client('s3', region_name='us-east-1')


# Creating a bucket 
# s3.create_bucket(Bucket= bucketName)

# print(f"Bucket '{bucketName}' created successfully!")



# Now Deleteing the bucket 

# Deleting the bucket
# s3.delete_bucket(Bucket=bucketName)

# print(f"Bucket '{bucketName}' deleted successfully")


# Lets sync some files to bucket

bucket_list = s3.list_buckets()
for bucket in bucket_list["Buckets"]:
    print(bucket["Name"])


BUCKET_NAME = input("Please Enter the bucket Name: ")
TEXT_FILE = "newfile.txt"
PHOTO_PATH = "Wallpaper.jpg"
REGION = "us-east-1"

# Create a text
with open(TEXT_FILE, "w") as f:
    f.write('Hello from Python!\n')
    f.write('This file is created and uploaded by boto3.\n')
print(f"Text file '{TEXT_FILE}' created locally")

# upload text to s3
s3.upload_file(TEXT_FILE, BUCKET_NAME, TEXT_FILE)
print(f"'{TEXT_FILE}' uploaded successfully to s3 bucket '{BUCKET_NAME}'")

if os.path.exists(PHOTO_PATH):
    s3.upload_file(PHOTO_PATH, BUCKET_NAME, PHOTO_PATH)
    print(f"'{PHOTO_PATH} uploaded successfully to s3 bucket '{BUCKET_NAME}'")
else:
    print(f"Photo '{PHOTO_PATH}' not found in current folder")