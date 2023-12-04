import os
import urllib.parse
import boto3
from email import policy
from email.parser import BytesParser

DEST_BUCKET = os.environ['DEST_BUCKET']
s3 = boto3.client('s3')

def handler(event, context):
    # Get the object from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    # Get email from S3
    response = s3.get_object(Bucket=bucket, Key=key)
    print('Email retrieved from S3')
    raw_email = response['Body'].read()

    email = BytesParser(policy=policy.default).parsebytes(raw_email)

    # Parse email attachment
    for parts in email.walk():
        if "attachment" == parts.get_content_disposition():
            # Check file type, only accept csv
            if parts.get_content_type() != 'text/csv':
                print("Invalid file type: " + parts.get_content_type())
                continue

            attachment = parts.get_payload(decode=True)

            # Get key from email
            email_key = email['Bank']

            # Save attachment in S3 and tag with email key
            s3.put_object(Bucket=DEST_BUCKET, Key=f"{email_key}-{parts.get_filename()}", Body=attachment)
            print('Attachment saved to S3')

    # Delete email from S3
    s3.delete_object(Bucket=bucket, Key=key)
    print('Email deleted from S3')


