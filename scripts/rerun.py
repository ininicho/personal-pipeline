import boto3
import json

BUCKET_NAME = 'nick-finances-expense'

# Get S3 bucket
s3 = boto3.resource('s3')
bucket = s3.Bucket(BUCKET_NAME)

# Trigger Lambda function with S3 event context
client = boto3.client('lambda')

# List all objects in bucket
for obj in bucket.objects.all():
    client.invoke(
        FunctionName='expense_processor',
        InvocationType='Event',
        Payload=json.dumps({
            "Records": [
                {
                    "s3": {
                        "bucket": {
                            "name": BUCKET_NAME
                        },
                        "object": {
                            "key": obj.key
                        }
                    }
                }
            ]
        })
    )

