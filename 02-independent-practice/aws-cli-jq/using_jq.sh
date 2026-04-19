#!/bin/bash

echo "--- Buckets report with jq ---"
echo ""

# Get the buckets names
BUCKETS=$(aws s3api list-buckets | jq -r '.Buckets[].Name')

for BUCKET in $BUCKETS; do
    echo "Bucket: $BUCKET"

    OBJECTS=$(aws s3api list-objects-v2 \
        --bucket $BUCKET 2>/dev/null \
        | jq -r '.Contents[]?.Key')

    if [ -z "$OBJECTS" ]; then
        echo "Empty Bucket"
    else
        echo "Files:"
        for OBJ in $OBJECTS; do 
            echo " - $OBJ"
        done
    fi
    echo ""
done