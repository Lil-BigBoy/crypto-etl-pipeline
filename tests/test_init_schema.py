import pytest  # noqa: F401
from unittest.mock import Mock
from crypto_lambda.init_schema import ensure_table_exists


def test_ensure_table_exists_success():
    # Create conn object
    mock_conn = Mock()

    # Run
    ensure_table_exists(mock_conn)

    # Assertions
    mock_conn.run.assert_called_once()
    args = mock_conn.run.call_args[0][0]
    assert "CREATE TABLE" in args


def test_ensure_table_exists_failure(capsys):
    # Create conn object and cause exception
    mock_conn = Mock()
    mock_conn.run.side_effect = Exception("some failure")

    # Run
    ensure_table_exists(mock_conn)

    # Assertions
    out = capsys.readouterr().out
    assert "Failed to ensure table exists" in out
    assert "some failure" in out
