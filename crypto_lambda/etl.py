import json
import os
from datetime import datetime, timezone
import boto3
from crypto_lambda import extract
from crypto_lambda import transform
from crypto_lambda import load

coins = ["bitcoin", "ethereum", "tether", "binancecoin", "solana"]

def lambda_handler(event, context):

    bucket_name = os.environ.get("CRYPTO_DATA_BUCKET")
    print(f"Fetching data for: {', '.join(coins)}")

    # STEP 1: Call to Extract
    try:
        data = extract.extract_data(coins)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return {"statusCode": 500, "body": "Failed to fetch data"}

    timestamp = datetime.now(timezone.utc).isoformat()
    s3 = boto3.client('s3')
    success_count_raw = 0
    success_count_processed = 0

    # STEP 2: Store all RAW data
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

    # STEP 3: Transform all raw records in one batch
    print("About to transform raw records...")
    try:
        transformed_records = transform.transform_data(raw_records)
        print(f"Transformation result: {transformed_records}")
    except Exception as e:
        print(f"Error during transformation: {e}")
        return {"statusCode": 500, "body": "Transformation failed"}

    # STEP 4: Store all transformed data
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

    # Step 5: Load to DB
    print("About to load transformed records to DB...")
    try:
        load.load_data(transformed_records)
        print("Coin data loaded to DB")
        loading = "SUCCESS"
    except Exception as e:
        print(f"Error during loading data: {e}")
        loading = "FAIL"

    # Determine weather the success was full or partial
    partial_failure = (
    success_count_raw < len(coins)
    or success_count_processed < len(coins)
    or loading == "FAIL"
    )

    status = 207 if partial_failure else 200

    return {
        "statusCode": status,
        "body": (
        f"Stored raw: {success_count_raw}, "
        f"processed: {success_count_processed} out of {len(coins)} coins. "
        f"Load to database = {loading}"
        )
    }
