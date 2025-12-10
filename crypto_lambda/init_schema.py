import os

def ensure_table_exists(conn):
    schema_path = os.path.join(os.path.dirname(__file__), "lambda_sql", "create_schema.sql")
    with open(schema_path, "r") as f:
        schema_sql = f.read()
    try:
        conn.run(schema_sql)
        print("✅ Table checked or created")
    except Exception as e:
        print(f"❌ Failed to ensure table exists: {e}")
