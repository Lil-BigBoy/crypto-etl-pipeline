import json
import os
import datetime
import requests
import boto3

# Crypto coin ETL hander
def lambda_handler(event, context):
    # Setup
    bucket_name = os.environ.get("CRYPTO_DATA_BUCKET")
    coins = ["bitcoin", "ethereum", "tether", "binancecoin", "solana"]
    coin_ids = ",".join(coins)
    print(f"Fetching data for: {coin_ids}")

    # Fetch data for all coins at once
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin_ids}&vs_currencies=usd"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
    except Exception as e:
        print(f"Error fetching data: {e}")
        return {"statusCode": 500, "body": "Failed to fetch data"}

    # Get timestamp for all records
    timestamp = datetime.datetime.utcnow().isoformat()
    s3 = boto3.client('s3')
    success_count = 0

    # Process and store each coin's data
    for coin in coins:
        price_info = data.get(coin)
        if not price_info or "usd" not in price_info:
            print(f"Skipping {coin}: Invalid data {price_info}")
            continue

        transformed_data = {
            "symbol": coin,
            "price_usd": price_info["usd"],
            "timestamp": timestamp
        }

        file_name = f"raw/{coin}_{timestamp}.json"
        try:
            s3.put_object(
                Bucket=bucket_name,
                Key=file_name,
                Body=json.dumps(transformed_data),
                ContentType='application/json'
            )
            print(f"Stored {coin} to {bucket_name}/{file_name}")
            success_count += 1
        except Exception as s3_error:
            print(f"Failed to store {coin}: {s3_error}")
    return {
        "statusCode": 200,
        "body": f"Successfully stored {success_count} out of {len(coins)} coin records"
    }

