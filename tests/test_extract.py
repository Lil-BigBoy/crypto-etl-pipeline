import pytest
import requests
from crypto_lambda import extract


def test_extract_data_success(monkeypatch):
    # Define fake API response
    fake_response = {"bitcoin": {"usd": 45000}}

    # Define a fake get() function to replace requests.get
    class MockResponse:
        def raise_for_status(self):  # Simulate successful status
            pass

        def json(self):  # Simulate JSON response
            return fake_response

    def mock_get(url):
        assert "ids=bitcoin,ethereum" in url  # URL formation check
        return MockResponse()

    # Monkeypatch requests.get to our fake version
    monkeypatch.setattr(requests, "get", mock_get)

    result = extract.extract_data(["bitcoin", "ethereum"])
    assert result == fake_response


def test_extract_data_http_error(monkeypatch):
    # Mock response to raise an HTTP error
    class MockResponse:
        def raise_for_status(self):
            raise requests.HTTPError("404 Client Error")

    def mock_get(url):
        return MockResponse()

    monkeypatch.setattr(requests, "get", mock_get)

    # Expect that extract_data raises the HTTPError
    with pytest.raises(requests.HTTPError):
        extract.extract_data(["bitcoin", "ethereum"])


def test_extract_data_malformed_json(monkeypatch):
    # Mock response to return malformed JSON (e.g., missing expected keys)
    class MockResponse:
        def raise_for_status(self):
            pass  # Simulate 200 OK

        def json(self):
            return {"unexpected_key": "oops"}  # Malformed structure

    def mock_get(url):
        return MockResponse()

    monkeypatch.setattr(requests, "get", mock_get)

    # The function should return what the API gave; downstream code should handle unexpected keys
    result = extract.extract_data(["bitcoin", "ethereum"])
    assert result == {"unexpected_key": "oops"}


def test_extract_data_empty_json(monkeypatch):
    # Mock response to return empty JSON
    class MockResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {}

    def mock_get(url):
        return MockResponse()

    monkeypatch.setattr(requests, "get", mock_get)

    result = extract.extract_data(["bitcoin", "ethereum"])
    assert result == {}
