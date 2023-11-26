import os

def handler(event, context):
    print("OS ENVIRONMENT VARIABLES")
    print(os.environ)
    return
