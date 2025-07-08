import json
import os
from datetime import datetime, timezone
import boto3
import extract

def lambda_handler(event, context):
    bucket_name = os.environ.get("CRYPTO_DATA_BUCKET")
    coins = ["bitcoin", "ethereum", "tether", "binancecoin", "solana"]
    print(f"Fetching data for: {', '.join(coins)}")

    try:
        data = extract.extract_data(coins)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return {"statusCode": 500, "body": "Failed to fetch data"}

    timestamp = datetime.now(timezone.utc).isoformat()
    s3 = boto3.client('s3')
    success_count = 0

    for coin in coins:
        price_info = data.get(coin)
        if not price_info or "usd" not in price_info:
            print(f"Skipping {coin}: Invalid data {price_info}")
            continue

        record = {
            "coin": coin,
            "price_usd": price_info["usd"],
            "timestamp": timestamp
        }

        file_name = f"raw/{coin}_{timestamp}.json"
        try:
            s3.put_object(
                Bucket=bucket_name,
                Key=file_name,
                Body=json.dumps(record),
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
