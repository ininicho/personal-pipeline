import io
import os
import csv
import boto3
import uuid
import hashlib
from decimal import Decimal
from datetime import datetime

AMEX_FIELDS = os.getenv('AMEX_FIELDS', 'date;id;amount;description;additional_info').split(';')
CIBC_FIELDS = os.getenv('CIBC_FIELDS', 'date;description;credit;debit').split(';')
# DB_FIELDS = id, amount, type, description, bank, note, category, date, created_at, updated_at

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DB_TABLE_NAME'])

def process_csv(csv_file, bank):
    """
    Open CSV file and update rows
    """
    # Sample row
    # 09/15/2023,"Reference: AT232600005000010335993"," 8.01","THE ALLEY #2 001 TORONTO","",

    if bank == 'AMEX': 
        reader = csv.DictReader(csv_file.splitlines(), fieldnames=AMEX_FIELDS)
    else:
        reader = csv.DictReader(csv_file.splitlines(), fieldnames=CIBC_FIELDS)

    # Update rows with DB fields
    with table.batch_writer(overwrite_by_pkeys=['id', 'date']) as batch:
        now = datetime.now()
        for row in reader:
            db_row = {}
            if bank == 'AMEX':
                # Update row
                db_row['amount'] = abs(Decimal(row['amount']))
                db_row['type'] = 'debit' if '-' in row['amount'] else 'credit'
                db_row['description'] = row['description']
                db_row['note'] = row['additional_info']
                db_row['date'] = row['date']

                # Generate ID
                transaction_date = datetime.strptime(row['date'], '%Y-%m-%d')
                transaction_id_str = f'{transaction_date.strftime("%Y%m%d")}-AMEX-{row["description"]}-{db_row["amount"]}'
                transaction_id = hashlib.md5(transaction_id_str.encode('utf-8')).hexdigest()
                db_row['id'] = str(uuid.UUID(transaction_id))
            else:
                # Update row
                db_row['amount'] = Decimal(row['credit']) if row['credit'] else Decimal(row['debit'])
                db_row['type'] = 'credit' if row['credit'] else 'debit'
                db_row['description'] = row['description']
                db_row['note'] = ''
                db_row['date'] = row['date']

                # Generate ID
                transaction_date = datetime.strptime(row['date'], '%Y-%m-%d')
                transaction_id_str = f'{transaction_date.strftime("%Y%m%d")}-CIBC-{row["description"]}-{db_row["amount"]}'
                transaction_id = hashlib.md5(transaction_id_str.encode('utf-8')).hexdigest()
                db_row['id'] = str(uuid.UUID(transaction_id))

            db_row['bank'] = bank
            db_row['category'] = ''
            db_row['created_at'] = now.strftime('%Y-%m-%d %H:%M:%S')
            db_row['updated_at'] = now.strftime('%Y-%m-%d %H:%M:%S')

            # Write row
            batch.put_item(Item=db_row)

# # Testing Locally
# with open('amex_test.csv', 'r') as csv_file:
#     process_csv(csv_file.read(), 'AMEX')
# 
# with open('cibc_credit_test.csv', 'r') as csv_file:
#     process_csv(csv_file.read(), 'CIBC')
# 
# with open('cibc_debit_test.csv', 'r') as csv_file:
#     process_csv(csv_file.read(), 'CIBC')
# 
# with open('cibc_savings_test.csv', 'r') as csv_file:
#     process_csv(csv_file.read(), 'CIBC')

