## Create a bucket 
aws s3 mb s3://metadata-janan-122


## Create a new file
echo "Hello Mr.Zabihullah" > hello.txt


## Upload file with metadata
aws s3api put-object --bucket metadata-janan-122 --key hello.txt --body hello.txt --metadata Practice=Metadata


## Get metadata through head object
aws s3api head-object --bucket metadata-janan-122 --key hello.txt

### OUTPUT
aws s3api head-object --bucket metadata-janan-122 --key hello.txt
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-05-26T20:16:34+00:00",
    "ContentLength": 20,
    "ETag": "\"bf4414621447966389d11b88c3eb7802\"",
    "ContentType": "binary/octet-stream",
    "ServerSideEncryption": "AES256",
    "Metadata": {
        # "practice": "Metadata"
    }
}

## Delete the bucket and file
aws s3 rb s3://metadata-janan-122 --force

