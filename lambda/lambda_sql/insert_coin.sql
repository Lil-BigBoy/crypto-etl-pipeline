INSERT INTO prices (coin, price_usd, timestamp, day_of_week)
VALUES (%s, %s, %s, %s)
ON CONFLICT (coin, timestamp) DO NOTHING;