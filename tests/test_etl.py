import os
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone

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
    from crypto_lambda import etl


def test_lambda_handler_success():
    event = {}
    context = {}

    # Mock extract output data
    mock_extract = {"bitcoin": {"usd": 100}, "ethereum": {"usd": 200}}

    # Mock transformed output data
    mock_transformed = [
        {"coin": "bitcoin", "price_usd": 100, "timestamp": "ts"},
        {"coin": "ethereum", "price_usd": 200, "timestamp": "ts"},
    ]

    mock_s3 = MagicMock()

    with patch("crypto_lambda.etl.extract.extract_data", return_value=mock_extract):
        with patch(
            "crypto_lambda.etl.transform.transform_data", return_value=mock_transformed
        ):
            with patch("crypto_lambda.etl.load.load_data") as mock_load:
                with patch("crypto_lambda.etl.boto3.client", return_value=mock_s3):
                    with patch(
                        "crypto_lambda.etl.os.environ",
                        {"CRYPTO_DATA_BUCKET": "mybucket"},
                    ):
                        with patch("crypto_lambda.etl.coins", ["bitcoin", "ethereum"]):
                            result = etl.lambda_handler(event, context)

    # Assertions
    assert result["statusCode"] == 200
    assert "Stored raw: 2, processed: 2" in result["body"]

    # S3 raw writes: 2 calls
    assert mock_s3.put_object.call_count >= 2

    # Transformed written: 2 more calls
    assert mock_s3.put_object.call_count == 4

    # Check that both filepaths were called
    called_keys = [call.kwargs["Key"] for call in mock_s3.put_object.call_args_list]
    assert any(k.startswith("raw/") for k in called_keys)
    assert any(k.startswith("processed/") for k in called_keys)

    # DB load called with full transformed list
    mock_load.assert_called_once_with(mock_transformed)


def test_lambda_handler_extract_failure():
    event = {}
    context = {}

    with patch(
        "crypto_lambda.etl.extract.extract_data", side_effect=Exception("API down")
    ):
        with patch("crypto_lambda.etl.boto3.client") as mock_s3:
            with patch("crypto_lambda.etl.transform.transform_data") as mock_transform:
                with patch("crypto_lambda.etl.load.load_data") as mock_load:
                    with patch(
                        "crypto_lambda.etl.os.environ",
                        {"CRYPTO_DATA_BUCKET": "mybucket"},
                    ):
                        result = etl.lambda_handler(event, context)

    # Assertions
    assert result["statusCode"] == 500
    assert "Failed to fetch data" in result["body"]

    # Nothing downstream should have been called
    mock_s3.assert_not_called()
    mock_transform.assert_not_called()
    mock_load.assert_not_called()


def test_lambda_handler_partial_raw_s3_failure():
    event = {}
    context = {}
    timestamp = "2025-01-01T12:00:00+00:00"

    # Mock extract → returns valid data for both
    mock_extracted = {"bitcoin": {"usd": 50000}, "ethereum": {"usd": 3500}}

    # Mock S3
    mock_s3 = MagicMock()
    mock_s3.put_object.side_effect = [
        Exception("S3 fail"),     # raw bitcoin fail
        None,                     # raw ethereum success
        None,                     # Dummy processed coin success
    ]

    with patch("crypto_lambda.etl.extract.extract_data", return_value=mock_extracted):
        # Freeze time for stable timestamps
        with patch("crypto_lambda.etl.datetime") as mock_datetime:
            mock_datetime.now.return_value = datetime.fromisoformat(timestamp)
            mock_datetime.timezone = timezone

            with patch("crypto_lambda.etl.boto3.client", return_value=mock_s3):
                with patch(
                    "crypto_lambda.etl.transform.transform_data",
                    return_value=[{"coin": "dummy"}],
                ) as mock_transform:
                    with patch("crypto_lambda.etl.load.load_data") as mock_load:
                        with patch(
                            "crypto_lambda.etl.os.environ",
                            {"CRYPTO_DATA_BUCKET": "mybucket"},
                        ):
                            result = etl.lambda_handler(event, context)

    # Assertions
    assert result["statusCode"] == 207                      # Partial sucess code
    assert "Stored raw: 1, processed: 1" in result["body"]  # Single raw success

    # Raw filenames form correctly
    assert (
        mock_s3.put_object.call_args_list[1].kwargs["Key"]
        == f"raw/ethereum_{timestamp}.json"
    )

    # Transform receives only successful raw records
    mock_transform.assert_called_once()
    raw_passed = mock_transform.call_args[0][0]
    assert list(raw_passed.keys()) == ["ethereum"]

    # Check the program continues after call to transform
    mock_load.assert_called_once_with([{"coin": "dummy"}])


def test_lambda_handler_transform_failure():
    event = {}
    context = {}

    # Mock extract → valid data
    mock_extracted = {"bitcoin": {"usd": 50000}, "ethereum": {"usd": 3500}}

    with patch("crypto_lambda.etl.extract.extract_data", return_value=mock_extracted):
        mock_s3 = MagicMock()
        with patch("crypto_lambda.etl.boto3.client", return_value=mock_s3):
            with patch(
                "crypto_lambda.etl.transform.transform_data",
                side_effect=Exception("Transform fail"),
            ) as _mock_transform:
                with patch("crypto_lambda.etl.load.load_data") as mock_load:
                    with patch(
                        "crypto_lambda.etl.os.environ",
                        {"CRYPTO_DATA_BUCKET": "mybucket"},
                    ):
                        result = etl.lambda_handler(event, context)

    # Assertions
    assert result["statusCode"] == 500
    assert "Transformation failed" in result["body"]

    # Nothing after transform should run
    mock_load.assert_not_called()
    assert mock_s3.put_object.call_count == 2  # only raw S3 writes


def test_lambda_handler_partial_processed_s3_failure():
    event = {}
    context = {}
    timestamp = "2025-01-01T12:00:00+00:00"

    mock_transformed = [
        {"coin": "bitcoin", "price_usd": 100, "timestamp": timestamp},
        {"coin": "ethereum", "price_usd": 200, "timestamp": timestamp},
    ]

    # Mock S3
    mock_s3 = MagicMock()
    mock_s3.put_object.side_effect = [
        None,                   # raw bitcoin success
        None,                   # raw ethereum success
        Exception("S3 fail"),   # processed bitcoin fail
        None,                   # processed ethereum success
    ]

    with patch(
        "crypto_lambda.etl.extract.extract_data",
        return_value={"bitcoin": {"usd": 0}, "ethereum": {"usd": 0}},
    ):
        with patch("crypto_lambda.etl.datetime") as mock_datetime:
            mock_datetime.now.return_value = datetime.fromisoformat(timestamp)
            mock_datetime.timezone = timezone

            with patch("crypto_lambda.etl.boto3.client", return_value=mock_s3):
                with patch(
                    "crypto_lambda.etl.transform.transform_data",
                    return_value=mock_transformed,
                ):
                    with patch("crypto_lambda.etl.load.load_data") as mock_load:
                        with patch(
                            "crypto_lambda.etl.os.environ",
                            {"CRYPTO_DATA_BUCKET": "mybucket"},
                        ):
                            with patch(
                                "crypto_lambda.etl.coins", ["bitcoin", "ethereum"]
                            ):
                                result = etl.lambda_handler(event, context)

    # Assertions -
    assert result["statusCode"] == 207                      # Partial sucess code
    assert "Stored raw: 2, processed: 1" in result["body"]  # Single processed success

    # Raw filenames form correctly
    assert (
        mock_s3.put_object.call_args_list[3].kwargs["Key"]
        == f"processed/ethereum_{timestamp}.json"
    )

    # Load is still called
    mock_load.assert_called_once()


def test_lambda_handler_load_failure():
    event = {}
    context = {}

    mock_extracted = {"bitcoin": {"usd": 100}, "ethereum": {"usd": 200}}
    mock_transformed = [
        {"coin": "bitcoin", "price_usd": 100, "timestamp": "ts"},
        {"coin": "ethereum", "price_usd": 200, "timestamp": "ts"},
    ]

    mock_s3 = MagicMock()
    mock_s3.put_object.side_effect = [None, None, None, None]

    with patch("crypto_lambda.etl.extract.extract_data", return_value=mock_extracted):
        with patch(
            "crypto_lambda.etl.transform.transform_data", return_value=mock_transformed
        ):
            with patch(
                "crypto_lambda.etl.load.load_data", side_effect=Exception("DB fail")
            ):
                with patch("crypto_lambda.etl.boto3.client", return_value=mock_s3):
                    with patch(
                        "crypto_lambda.etl.os.environ",
                        {"CRYPTO_DATA_BUCKET": "mybucket"},
                    ):
                        result = etl.lambda_handler(event, context)

    # Assertions
    assert result["statusCode"] == 207
    assert "Load to database = FAIL" in result["body"]

    # S3 uploads should still have happened
    assert mock_s3.put_object.call_count == 4
    assert "Stored raw: 2, processed: 2" in result["body"]
