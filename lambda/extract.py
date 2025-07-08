import requests

def extract_data(coins):
    coin_ids = ",".join(coins)
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin_ids}&vs_currencies=usd"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()
