import urllib.parse
import boto3
import csv

s3 = boto3.client('s3')

def handler(event, context):
    # Get the object from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    # Get CSV from S3
    response = s3.get_object(Bucket=bucket, Key=key)
    print('CSV retrieved from S3')
    raw_file = response['Body'].read()

    # Read CSV file
    reader = csv.DictReader(raw_file.decode('utf-8').splitlines())
    print('CSV file read')

    # Print first row
    print(next(reader))
