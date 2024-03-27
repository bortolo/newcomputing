import json

print('Loading function')

def lambda_handler(event, context):
    print(event)
    return "success"
