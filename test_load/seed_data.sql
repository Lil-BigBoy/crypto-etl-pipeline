-- Insert 3 seed rows into test_crypto_prices

INSERT INTO test_crypto_prices (coin, price_usd, timestamp, day_of_week)
VALUES 
  ('seedcoin_1', 1.11, '2024-01-01T00:00:00Z', 'Monday'),
  ('seedcoin_2', 2.22, '2024-01-02T00:00:00Z', 'Tuesday'),
  ('seedcoin_3', 3.33, '2024-01-03T00:00:00Z', 'Wednesday');
