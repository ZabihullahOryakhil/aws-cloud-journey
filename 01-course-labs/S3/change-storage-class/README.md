## Create a bucket
aws s3 mb s3://class-janan-122


## Create a file
echo "Besmellah" > hello.txt
aws s3 cp hello.txt s3://class-janan-122
aws s3 cp hello.txt s3://class-janan-122 --storage-class STANDARD_IA


## CLEANUP
aws s3 rb s3://class-janan-122 --force
