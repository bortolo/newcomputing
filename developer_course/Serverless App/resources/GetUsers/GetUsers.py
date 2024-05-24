import json
import boto3
import os
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Initialize a session using Amazon DynamoDB
    dynamodb = boto3.resource('dynamodb')
    
    # Specify the table
    table_name = os.environ['ListOfUsers_table']
    table = dynamodb.Table(table_name)
    
    # Scan the table
    try:
        response = table.scan()
        items = response.get('Items', [])
        
        # Handle potential pagination
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response.get('Items', []))
        
        # Return the items
        return {
            'statusCode': 200,
            'body': json.dumps(items)
        }
    
    except ClientError as e:
        # Return an error message if something goes wrong
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error scanning table: {e.response["Error"]["Message"]}')
        }
