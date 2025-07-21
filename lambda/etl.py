import json
import os
from datetime import datetime, timezone
import boto3
import extract
import transform

def lambda_handler(event, context):
    bucket_name = os.environ.get("CRYPTO_DATA_BUCKET")
    coins = ["bitcoin", "ethereum", "tether", "binancecoin", "solana"]
    print(f"Fetching data for: {', '.join(coins)}")

    # Call to Extract
    try:
        data = extract.extract_data(coins)  # data is a batch: {"bitcoin": {"usd": 12345}, ...}
    except Exception as e:
        print(f"Error fetching data: {e}")
        return {"statusCode": 500, "body": "Failed to fetch data"}

    timestamp = datetime.now(timezone.utc).isoformat()
    s3 = boto3.client('s3')
    success_count_raw = 0
    success_count_processed = 0

    # STEP 1: Store all RAW data
    raw_records = {}
    for coin in coins:
        price_info = data.get(coin)
        if not price_info or "usd" not in price_info:
            print(f"Skipping {coin}: Invalid data {price_info}")
            continue

        raw_record = {
            "coin": coin,
            "price_usd": price_info["usd"],
            "timestamp": timestamp
        }

        raw_file_name = f"raw/{coin}_{timestamp}.json"
        try:
            s3.put_object(
                Bucket=bucket_name,
                Key=raw_file_name,
                Body=json.dumps(raw_record),
                ContentType='application/json'
            )
            print(f"Stored RAW {coin} to {bucket_name}/{raw_file_name}")
            success_count_raw += 1
            raw_records[coin] = raw_record
        except Exception as s3_error:
            print(f"Failed to store raw {coin}: {s3_error}")
            continue

    # STEP 2: Transform all raw records in one batch
    print("About to transform raw records...")
    try:
        transformed_records = transform.transform_data(raw_records)
        print(f"Transformation result: {transformed_records}")
    except Exception as e:
        print(f"Error during transformation: {e}")
        return {"statusCode": 500, "body": "Transformation failed"}

    # STEP 3: Store all transformed data
    print("Storing transformed records...")
    for record in transformed_records:
        coin = record["coin"]
        processed_file_name = f"processed/{coin}_{timestamp}.json"
        try:
            s3.put_object(
                Bucket=bucket_name,
                Key=processed_file_name,
                Body=json.dumps(record),
                ContentType='application/json'
            )
            print(f"Stored PROCESSED {coin} to {bucket_name}/{processed_file_name}")
            success_count_processed += 1
        except Exception as s3_error:
            print(f"Failed to store processed {coin}: {s3_error}")

    return {
        "statusCode": 200,
        "body": f"Stored raw: {success_count_raw}, processed: {success_count_processed} out of {len(coins)} coins"
    }
