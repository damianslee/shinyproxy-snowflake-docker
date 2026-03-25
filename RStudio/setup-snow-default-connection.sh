#!/bin/sh
# Preconfigure Snowflake CLI default connection from SPCS-injected env vars and session token.
# SPCS sets: SNOWFLAKE_ACCOUNT, SNOWFLAKE_HOST, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA,
# and optionally SNOWFLAKE_WAREHOUSE, SNOWFLAKE_ROLE. Token at /snowflake/session/token.
# Only runs when token file and SNOWFLAKE_ACCOUNT are present (idempotent).
# Uses HOME (e.g. HOME=/home/rstudio for RStudio container).

if [ ! -f /snowflake/session/token ] || [ -z "${SNOWFLAKE_ACCOUNT}" ]; then
  return 0 2>/dev/null || true
  exit 0
fi

SNOW_CONF_DIR="${HOME:-/root}/.snowflake"
mkdir -p "$SNOW_CONF_DIR"
CONF_FILE="$SNOW_CONF_DIR/connections.toml"

# Write [default] connection from env (quote values for TOML)
{
  echo '[default]'
  echo "account = \"${SNOWFLAKE_ACCOUNT}\""
  [ -n "$SNOWFLAKE_HOST" ] && echo "host = \"${SNOWFLAKE_HOST}\""
  [ -n "$SNOWFLAKE_DATABASE" ] && echo "database = \"${SNOWFLAKE_DATABASE}\""
  [ -n "$SNOWFLAKE_SCHEMA" ] && echo "schema = \"${SNOWFLAKE_SCHEMA}\""
  [ -n "$SNOWFLAKE_WAREHOUSE" ] && echo "warehouse = \"${SNOWFLAKE_WAREHOUSE}\""
  [ -n "$SNOWFLAKE_ROLE" ] && echo "role = \"${SNOWFLAKE_ROLE}\""
  echo 'authenticator = "oauth"'
  echo 'token_file_path = "/snowflake/session/token"'
} > "$CONF_FILE"
chmod 600 "$CONF_FILE"
export SNOWFLAKE_DEFAULT_CONNECTION_NAME=default
