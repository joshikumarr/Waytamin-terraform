import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Log the incoming event
    logger.info("Received event: %s", json.dumps(event))

    # Validate and extract input query directly from the event
    try:
        body = json.loads(event['body'])
        input_query = body['query']
        if not input_query:
            raise ValueError("Empty query field")
    except KeyError as e:
        logger.error("Invalid input: Missing 'query' key")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid or missing query field'})
        }
    except ValueError as e:
        logger.error("Invalid input: %s", str(e))
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Empty query field'})
        }

    # Initialize AWS Comprehend client
    comprehend = boto3.client('comprehend', region_name='us-west-2')

    # Call AWS Comprehend to detect entities
    try:
        response = comprehend.detect_entities(Text=input_query, LanguageCode='en')
        entities = response['Entities']
        logger.info("Detected entities: %s", json.dumps(entities))
    except boto3.exceptions.Boto3Error as boto_err:
        logger.error("AWS SDK error: %s", str(boto_err))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'AWS SDK error occurred'})
        }
    except Exception as e:
        logger.error("Unexpected error: %s", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'An unexpected error occurred'})
        }

    # Successful processing
    return {
        'statusCode': 200,
        'body': json.dumps({'entities': entities})
    }
