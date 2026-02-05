import pytest  # noqa: F401
import os
from unittest.mock import MagicMock, patch

# Fake environment variables
env_vars = {
    "DB_HOST": "localhost",
    "DB_PORT": "5432",
    "DB_NAME": "testdb",
    "DB_USER": "user",
    "DB_PASSWORD": "pass",
    "TABLE_NAME": "coins",
}
# Patch in fake env vars before load.py attempts to find them in Terraform
with patch.dict(os.environ, env_vars):
    from crypto_lambda import load


def test_load_data_success():
    records = [
        {
            "coin": "bitcoin",
            "price_usd": 50000,
            "timestamp": "2025-11-25T12:00:00+00:00",
        },
        {
            "coin": "ethereum",
            "price_usd": 3500,
            "timestamp": "2025-11-25T12:00:00+00:00",
        },
    ]

    # Create a mock cursor
    mock_cursor = MagicMock()
    # Create a mock connection that returns the mock cursor
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = mock_cursor

    # Patch pg8000.connect to return the mock connection
    with patch("crypto_lambda.load.pg8000.connect", return_value=mock_conn):
        # Also patch ensure_table_exists to avoid side effects
        with patch("crypto_lambda.load.ensure_table_exists") as mock_ensure:
            load.load_data(records)

    # Assertions:

    # ensure_table_exists should be called once with the connection
    mock_ensure.assert_called_once_with(mock_conn)
    # Ensure connection methods called
    mock_conn.cursor.assert_called_once()
    assert mock_cursor.execute.call_count == 2
    mock_conn.commit.assert_called_once()
    mock_conn.close.assert_called_once()

    # Assert that each individual call to .execute received the exact expected params
    btc_params = mock_cursor.execute.call_args_list[0][0][1]
    eth_params = mock_cursor.execute.call_args_list[1][0][1]

    assert btc_params == ("bitcoin", 50000, "2025-11-25T12:00:00+00:00", "Tuesday")
    assert eth_params == ("ethereum", 3500, "2025-11-25T12:00:00+00:00", "Tuesday")


def test_load_data_db_connection_failure():
    records = [
        {
            "coin": "bitcoin",
            "price_usd": 50000,
            "timestamp": "2025-11-25T12:00:00+00:00",
        }
    ]

    # Patch pg8000.connect to raise an exception (simulating DB down)
    with patch("crypto_lambda.load.pg8000.connect", side_effect=Exception("DB down")):
        # Patch ensure_table_exists to assert downstream code is not called
        with patch("crypto_lambda.load.ensure_table_exists") as mock_ensure:
            load.load_data(records)


def test_load_data_insert_failure():
    records = [
        {
            "coin": "bitcoin",
            "price_usd": 50000,
            "timestamp": "2025-11-25T12:00:00+00:00",
        },
        {
            "coin": "ethereum",
            "price_usd": 3500,
            "timestamp": "2025-11-25T12:00:00+00:00",
        },
    ]

    mock_cursor = MagicMock()
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = mock_cursor

    # Make first insert succeed, second insert raise
    def execute_side_effect(sql, params):
        if params[0] != "ethereum":
            raise Exception("Insert failed")

    mock_cursor.execute.side_effect = execute_side_effect

    with patch("crypto_lambda.load.pg8000.connect", return_value=mock_conn):
        with patch("crypto_lambda.load.ensure_table_exists"):
            load.load_data(records)

    # Assertions
    assert mock_cursor.execute.call_count == 2
    mock_conn.commit.assert_called_once()
    mock_conn.close.assert_called_once()


def test_load_data_bad_timestamp():
    records = [
        {"coin": "bitcoin", "price_usd": 50000, "timestamp": "NAUGHTY_TIMESTAMP"},
        {
            "coin": "ethereum",
            "price_usd": 3500,
            "timestamp": "2025-11-25T12:00:00+00:00",
        },
    ]

    mock_cursor = MagicMock()
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = mock_cursor

    with patch("crypto_lambda.load.pg8000.connect", return_value=mock_conn):
        with patch("crypto_lambda.load.ensure_table_exists"):
            load.load_data(records)

    # Assertions
    assert mock_cursor.execute.call_count == 1
    executed_params = mock_cursor.execute.call_args[0][1]
    assert executed_params[0] == "ethereum"
    mock_conn.commit.assert_called_once()
    mock_conn.close.assert_called_once()


def test_load_data_empty_records():
    records = []

    mock_cursor = MagicMock()
    mock_conn = MagicMock()
    mock_conn.cursor.return_value = mock_cursor

    with patch("crypto_lambda.load.pg8000.connect", return_value=mock_conn):
        with patch("crypto_lambda.load.ensure_table_exists") as mock_ensure:
            load.load_data(records)

    # Assertions
    mock_ensure.assert_called_once()
    mock_cursor.execute.assert_not_called()
    mock_conn.commit.assert_called_once()
    mock_conn.close.assert_called_once()
