import json
import os
import requests


def lambda_handler(event, context):

    bucket_name = os.environ['CRYPTO_DATA_BUCKET']
    crypto = event.get("crypto", "bitcoin")  # default to 'bitcoin'
    bucket_name = os.environ.get("CRYPTO_DATA_BUCKET")
    print(f"Fetching data for: {crypto}")

    url = f"https://api.coingecko.com/api/v3/simple/price?ids={crypto}&vs_currencies=usd"
    response = requests.get(url)
    price_data = response.json()
    print(f"Price data: {price_data}")

    print(f"Using bucket: {bucket_name}")
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete!')
    }
