
## Create website 1

## Create a bucket
aws s3 mb s3://cors-janan-33

## Change block public access
aws s3api put-public-access-block \
    --bucket cors-janan-33 \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false"

## create a bucket policy
aws s3api put-bucket-policy --bucket cors-janan-33 --policy file://policy.json

## Turn on Static website hosting
aws s3api put-bucket-website --bucket cors-janan-33 --website-configuration file://website.json

## Upload our index.html file and include a resource that would be cross-origin
aws s3 cp index.html s3://cors-janan-33

## Get the website endpoint for s3
http://cors-janan-33.s3-website-us-east-1.amazonaws.com





## Create website 2

## Create bucket 
aws s3 mb s3://cors-janan-3378

## Change block public access
aws s3api put-public-access-block \
    --bucket cors-janan-3378 \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false"

## create a bucket policy
aws s3api put-bucket-policy --bucket cors-janan-3378 --policy file://policy2.json

## Turn on Static website hosting
aws s3api put-bucket-website --bucket cors-janan-3378 --website-configuration file://website.json

## Upload our javascript file 
aws s3 cp hello.js s3://cors-janan-3378



## Create API Gateway with mock response and then test the endpoint

curl -X POST "https://l7m0nxxmp7.execute-api.us-east-1.amazonaws.com/prod/Hello" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "value"
  }'