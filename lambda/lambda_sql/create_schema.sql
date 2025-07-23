CREATE TABLE IF NOT EXISTS crypto_prices (
    id SERIAL PRIMARY KEY,
    coin VARCHAR(100) NOT NULL,
    price_usd NUMERIC(18, 8) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (coin, timestamp)
);
