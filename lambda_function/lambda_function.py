import json
import boto3
import logging
import urllib3
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Map city names to airport codes
airport_codes = {
    "phoenix": "PHX",
    "denver": "DEN",
    "hyderabad": "HYD"
}

def get_wait_time(airport_code):
    # Make the GET request to the TSA wait times API
    http = urllib3.PoolManager()
    url = f"https://www.tsawaittimes.com/api/airport/1HK88q5aOH23NcSENHnOh3Bg3AMcTusO/{airport_code}/json"
    response = http.request('GET', url)

    # Parse the response
    if response.status == 200:
        data = json.loads(response.data.decode('utf-8'))
        return {
            "airport_location": airport_code,
            "current_wait_time": data.get("rightnow"),
            "current_wait_time_description": data.get("rightnow_description", "N/A")
        }
    else:
        logger.error(f"Failed to get wait time for {airport_code} with status {response.status}")
        return None

def lambda_handler(event, context):
    try:
        # Validate input query
        body = json.loads(event.get('body', '{}'))
        input_query = body.get('query', '').strip()

        # Initialize AWS Comprehend client
        comprehend = boto3.client('comprehend', region_name='us-west-2')

        # Detect entities using Comprehend
        comprehend_response = comprehend.detect_entities(Text=input_query, LanguageCode='en')
        entities = comprehend_response['Entities']

        # Process detected entities with type 'LOCATION'
        with ThreadPoolExecutor() as executor:
            results = []
            for entity in entities:
                if entity['Type'] == 'LOCATION':
                    airport_location = entity['Text'].lower()
                    airport_code = airport_codes.get(airport_location)
                    if airport_code:
                        future = executor.submit(get_wait_time, airport_code)
                        results.append(future)
                    else:
                        logger.info(f"Airport code not found for location: {airport_location}")
                        results.append(None)

            # Aggregate results
            wait_times = [future.result() for future in results if future]

        # Return response
        return {
            'statusCode': 200,
            'body': json.dumps({"entities": wait_times})
        }

    except ValueError as e:
        logger.error(str(e))
        return {
            'statusCode': 400,
            'body': json.dumps({'error': str(e)})
        }
    except Exception as e:
        logger.error(f"An unexpected error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'An unexpected error occurred'})
        }
        