from crypto_lambda import transform


def test_transform_data_success():
    input_data = {
        "bitcoin": {"price_usd": 50000},
        "ethereum": {"price_usd": 3500},
    }

    result = transform.transform_data(input_data)

    # Should return a list with two items
    assert isinstance(result, list)
    assert len(result) == 2

    # Check structure of an entry
    entry = result[0]
    assert "coin" in entry
    assert "price_usd" in entry
    assert "timestamp" in entry

    # Check values match input (order not guaranteed but fine)
    coins = [item["coin"] for item in result]
    assert "bitcoin" in coins
    assert "ethereum" in coins

    # Check timestamp consistency (all timestamps identical)
    timestamps = {item["timestamp"] for item in result}
    assert len(timestamps) == 1


def test_transform_data_skips_invalid():
    input_data = {
        "bitcoin": {"price_usd": 50000},    # valid
        "ethereum": {},                     # empty dict → skipped
        "solana": None,                     # None → skipped
        "tether": {"usd": 1.0},             # missing price_usd → skipped
    }

    result = transform.transform_data(input_data)

    # Only bitcoin should be included
    assert len(result) == 1
    assert result[0]["coin"] == "bitcoin"
    assert result[0]["price_usd"] == 50000
