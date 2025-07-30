#!/bin/bash

# Exit with a helpful echo if any command fails
set -e
trap 'echo "❌ Script failed in ${BASH_SOURCE[0]} at line $LINENO"; exit 1' ERR

# Make the test_load dir the working dir, no matter where this script was run from
cd "$(dirname "${BASH_SOURCE[0]}")"
echo ""
echo "➡️ Made the local dir the CWD"
echo ""

# Load environment variables from .env.test
echo "📦 Loading environment variables..."
set -a
. .env.test
set +a
echo "✅ Environment loaded."
echo ""

# Run schema creation SQL
echo "📐 Creating database schema..."
psql -d "$PGDATABASE" -f create_test_schema.sql
echo "✅ Schema applied."
echo ""

# Seed the DB with test rows
echo "🌱 Inserting seed data..."
psql -d "$PGDATABASE" -f seed_data.sql
echo "✅ Seed data inserted."
echo ""

# Run the load.py script to insert data from test_coins.json
echo "🚀 Running Python ETL load.py..."
python3 ../lambda/load.py
echo "✅ load.py complete. Additional test rows attempted."
echo ""

# Final status
echo "🔍 Confirming row count in $PGDATABASE's test table..."
row_count=$(psql -d "$PGDATABASE" -t -c "SELECT COUNT(*) FROM test_crypto_prices;" | xargs)
echo "✅ Row count: $row_count (expected: 6)"
