from datetime import datetime, timezone

def transform_data(data):
    """ Returns a list of dict: Transformed list of coin data with coin name, price, and timestamp. """

    timestamp = datetime.now(timezone.utc).isoformat()
    transformed_list = []

    for coin, record in data.items():
        if record and "price_usd" in record:
            transformed_list.append({
                "coin": coin,
                "price_usd": record["price_usd"],
                "timestamp": timestamp
            })

    return transformed_list
