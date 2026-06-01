## Create a bucket
aws s3 mb s3://bucket-policy-janan-33

## Create a File 
echo "This is Cross-Account bucket policy" > file.txt

## Upload the file to the bucket
aws s3 cp "file.txt" s3://bucket-policy-janan-33

## 
aws s3api put-bucket-policy --bucket bucket-policy-janan-33 --policy file://policy.json


## What happened in Account B
 $ aws s3 ls s3://bucket-policy-janan-33
2026-06-01 11:03:20         36 file.txt
~ $ touch newfile.txt
~ $ ls
newfile.txt

### Here I wanted to upload a file to the bucket but access denied, So I updated the policy
~ $ aws s3 cp "newfile.txt" s3://bucket-policy-janan-33
upload failed: ./newfile.txt to s3://bucket-policy-janan-33/newfile.txt An error occurred (AccessDenied) when calling the PutObject operation: Access Denied

# Here I did upload again and worked completely okay
~ $ aws s3 cp "newfile.txt" s3://bucket-policy-janan-33
upload: ./newfile.txt to s3://bucket-policy-janan-33/newfile.txt
~ $ ^C


## Cleanup
aws s3 rb s3://bucket-policy-janan-33 --force