# showdatabases.py
# Test Snowflake connectivity from within code-server using the Snowflake Python connector.
#
# For Snowflake SPCS, token-based OAuth is available via:
#   authenticator="oauth"
#   token_file_path="/snowflake/session/token"
#
# The container should also have SPCS env vars injected by Snowflake:
#   SNOWFLAKE_ACCOUNT, SNOWFLAKE_HOST (optional), SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA, etc.

import os

import snowflake.connector


def getenv(name: str, default=None):
    v = os.environ.get(name)
    return default if v is None or v == "" else v


def main():
    token_path = "/snowflake/session/token"
    if not os.path.exists(token_path):
        raise SystemExit(f"WARNING: token not found at {token_path}")

    account = getenv("SNOWFLAKE_ACCOUNT")
    if not account:
        raise SystemExit("WARNING: SNOWFLAKE_ACCOUNT env var not set")

    host = getenv("SNOWFLAKE_HOST")
    if not host:
        host = f"{account}.snowflakecomputing.com"

    # User may or may not be required depending on how the OAuth token is minted.
    # Your RStudio image uses SNOWFLAKE_USER as UID when building the ODBC DSN,
    # so we include it if provided.
    user = getenv("SNOWFLAKE_USER")

    params = {
        "account": account,
        "host": host,
        "authenticator": "oauth",
        "token_file_path": token_path,
    }

    warehouse = getenv("SNOWFLAKE_WAREHOUSE")
    database = getenv("SNOWFLAKE_DATABASE")
    schema = getenv("SNOWFLAKE_SCHEMA")
    role = getenv("SNOWFLAKE_ROLE")

    if user:
        params["user"] = user
    if warehouse:
        params["warehouse"] = warehouse
    if database:
        params["database"] = database
    if schema:
        params["schema"] = schema
    if role:
        params["role"] = role

    conn = snowflake.connector.connect(**params)
    try:
        with conn.cursor() as cur:
            cur.execute("SHOW DATABASES")
            rows = cur.fetchall()

            # Tabular output so it's readable in the code-server terminal.
            headers = [d[0] for d in (cur.description or [])]
            if not headers:
                print(rows)
                return

            # Keep output reasonable in terminals; adjust as needed.
            max_rows = int(getenv("SHOWDATABASES_MAX_ROWS", "200"))
            if len(rows) > max_rows:
                print(f"Showing first {max_rows} of {len(rows)} rows...")
                rows = rows[:max_rows]

            widths = []
            for col_idx, header in enumerate(headers):
                # Convert all values to strings first to size columns accurately.
                col_vals = [header] + [
                    ("" if r[col_idx] is None else str(r[col_idx])) for r in rows
                ]
                widths.append(max(len(v) for v in col_vals) + 2)

            def fmt_cell(val, width):
                s = "" if val is None else str(val)
                return s.ljust(width)

            def fmt_row(row):
                return "".join(fmt_cell(row[i], widths[i]) for i in range(len(headers)))

            print(fmt_row(headers))
            print("".join("-" * w for w in widths))
            for r in rows:
                print(fmt_row(r))
    finally:
        conn.close()


if __name__ == "__main__":
    main()

