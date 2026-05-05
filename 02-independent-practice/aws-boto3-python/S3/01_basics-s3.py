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
    name = bucket['Name']
    created = bucket['CreationDate']
    print(f"    Bucket: {name}")
    print(f"    Created: {created}")
    print(f" -------")

# Creating A bucket
print("")
print("-" * 20)
print("Creating a new bucket")
print("-" * 20)

ShouldCreate = input("Do you wanna create a new bucket or not (YES/NO): ").strip().lower()
if ShouldCreate not in ["yes", "no"]: 
    print("Invalid input -> please type YES or NO!")
elif ShouldCreate == "yes":
    BUCKET_NAME = input("Please Enter the Bucket name: ")
    if len(BUCKET_NAME) < 3 or len(BUCKET_NAME) > 63:
        print("Error: bucket name must be between 3 and 63 characters")
    elif " " in BUCKET_NAME:
        print("Error: bucket name cannot contain spaces")
    else:

        try:
            s3.create_bucket(Bucket=BUCKET_NAME)
            print(f"    Created: {BUCKET_NAME}")

            # Uploading a file
            print("")
            print("-" * 20)
            print("Uploading a file")
            print("-" * 20)

            with open("/tmp/boto3_test.txt", "w") as f:
                f.write(f"Hello from boto3\nTimestamp: {datetime.now()}")

            try:
                s3.upload_file(
                Filename="/tmp/boto3_test.txt",
                Bucket=BUCKET_NAME,
                Key="test/boto3_test.txt"
                )
                print(f"    Uploaded boto3_test.txt -> s3://{BUCKET_NAME}/test/")
            except Exception as e:
                print(f"    Upload Error: {e}")

            # Getting all the objects
            print("")
            print("-" * 20)
            print(f"Objects in {BUCKET_NAME}")
            print("-" * 20)

            try:
                objects = s3.list_objects_v2(Bucket=BUCKET_NAME)

                if objects['KeyCount'] == 0:
                    print(" Empty bucket")
                else:
                    for obj in objects['Contents']:
                        print(f"    File: {obj['Key']}")
                        print(f"    Size: {obj['Size']} bytes")
                        print("------")

            except Exception as e:
                print(f"    Error: {e}")

            # Downloading the the file back        
            print("")
            print("-" * 20)
            print("Downloading file back")
            print("-" * 20)

            try:
                s3.download_file(
                Bucket=BUCKET_NAME,
                Key="test/boto3_test.txt",
                Filename="/tmp/boto3_downloaded.txt"
            )
                print(" Downloaded to /tmp/boto3_downloaded.txt")

                with open("/tmp/boto3_downloaded.txt", "r") as f:
                    print(f"    Content: {f.read()}")
            except Exception as e:
                print(f"    Download Error: {e}")

            # Deleting the file back
            print("")
            print("-" * 20)
            print("Deleting object")
            print("-" * 20)

            try:
                s3.delete_object(
                Bucket=BUCKET_NAME,
                Key="test/boto3_test.txt"
                )

                print(f"    Deleted successfully: test/boto3_test.txt")

            except Exception as e:
                print(f" Delete error: {e}")

            print("")
            print("Done")


        except s3.exceptions.BucketAlreadyOwnedByYou:
            print(f"    already exists: {BUCKET_NAME}")
        except Exception as e:  
            print(f"    Error: {e}")
else:
    print("Skipped. Good Luck!")
        




# Uplaoding a file
# print("")
# print("-" * 20)
# print("Uploading a file")
# print("-" * 20)

# with open("/tmp/boto3_test.txt", "w") as f:
#     f.write(f"Hello from boto3\nTimestamp: {datetime.now()}")

# try:
#     s3.upload_file(
#         Filename="/tmp/boto3_test.txt",
#         Bucket=BUCKET_NAME,
#         Key="test/boto3_test.txt"
#     )
#     print(f"    Uploaded boto3_test.txt -> s3://{BUCKET_NAME}/test/")
# except Exception as e:
#     print(f"    Upload Error: {e}")

# List objects in bucket
# print("")
# print("-" * 20)
# print(f"Objects in {BUCKET_NAME}")
# print("-" * 20)

# try:
#     objects = s3.list_objects_v2(Bucket=BUCKET_NAME)

#     if objects['KeyCount'] == 0:
#         print(" Empty bucket")
#     else:
#         for obj in objects['Contents']:
#             print(f"    File: {obj['Key']}")
#             print(f"    Size: {obj['Size']} bytes")
#             print("------")

# except Exception as e:
#     print(f"    Error: {e}")

# Download the file back
# print("")
# print("-" * 20)
# print("Downloading file back")
# print("-" * 20)

# try:
#     s3.download_file(
#         Bucket=BUCKET_NAME,
#         Key="test/boto3_test.txt",
#         Filename="/tmp/boto3_downloaded.txt"
#     )
#     print(" Downloaded to /tmp/boto3_downloaded.txt")

#     with open("/tmp/boto3_downloaded.txt", "r") as f:
#         print(f"    Content: {f.read()}")
# except Exception as e:
#     print(f"    Download Error: {e}")



# Delete the object
# print("")
# print("-" * 20)
# print("Deleting object")
# print("-" * 20)

# try:
#     s3.delete_object(
#         Bucket=BUCKET_NAME,
#         Key="test/boto3_test.txt"
#     )

#     print(f"    Deleted successfully: test/boto3_test.txt")

# except Exception as e:
#     print(f" Delete error: {e}")

# print("")
# print("Done")