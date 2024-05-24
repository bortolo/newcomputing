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

    # Extract item details from the event (assuming the item details are in the event body)
    try:
        
        body = event['body']
        
        # Check if body is a string and needs to be parsed
        if isinstance(body, str):
            item = json.loads(body)
        elif isinstance(body, dict):
            item = body
        else:
            raise ValueError("Invalid body format")

        
        # Use a conditional expression to ensure the item does not already exist
        response = table.put_item(
            Item=item,
            ConditionExpression='attribute_not_exists(UserId)'  # Ensure that PrimaryKey does not already exist
        )
        
        # Return a success message
        return {
            'statusCode': 200,
            'body': json.dumps('Item added successfully!')
        }
    
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            # Item with the same PrimaryKey already exists
            return {
                'statusCode': 400,
                'body': json.dumps('Item with the same PrimaryKey already exists')
            }
        else:
            # Return an error message if something else goes wrong
            return {
                'statusCode': 500,
                'body': json.dumps(f'Error adding item: {e.response["Error"]["Message"]}')
            }
    
    except (ValueError, KeyError) as e:
        # Return an error message if the event does not have the expected format
        return {
            'statusCode': 400,
            'body': json.dumps(f'Invalid input: {str(e)}')
        }