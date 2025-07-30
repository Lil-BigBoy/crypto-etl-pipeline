from datetime import datetime
import os
import json
import psycopg2

# Loading environment variables
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
TABLE_NAME = os.getenv("TABLE_NAME")

# Loading SQL insert statement
with open("../lambda/lambda_sql/insert_coin.sql", "r") as f:
    raw_sql = f.read().strip()

INSERT_SQL = raw_sql.replace("{{TABLE_NAME}}", TABLE_NAME)

# Loading coin records to DB
def load_data(records):
    
    print(f"Starting load of {len(records)} records")

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )
    except Exception as conn_error:
        print(f"Failed to connect to DB: {conn_error}")
        return
    
    try:
        with conn:
            with conn.cursor() as cursor:
                for record in records:
                    try:
                        dt = datetime.fromisoformat(record["timestamp"].replace("Z", "+00:00"))
                        day_of_week = dt.strftime("%A")

                        params = (
                            record["coin"],
                            record["price_usd"],
                            record["timestamp"],
                            day_of_week,
                        )
                        cursor.execute(INSERT_SQL, params)
                        print(f"Inserted: {record['coin']}")
                    except Exception as e:
                        print(f"Failed to insert {record['coin']}: {e}")
    finally:
        conn.close()
    print("Connection successfully closed")

# For local testing
if __name__ == "__main__":
    try:
        with open("../test_load/test_coins.json", "r") as f:
            transformed_records = json.load(f)
        load_data(transformed_records)
    except Exception as e:
        print(f"Error during local testing: {e}")
