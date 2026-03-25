#!/usr/bin/with-contenv bash
# At container start: Snowflake CLI + ODBC DSN for rstudio user when running in SPCS (token + env vars).
set -e

RSTUDIO_HOME="${RSTUDIO_HOME:-/home/rstudio}"
if [[ ! -d "$RSTUDIO_HOME" ]]; then
  exit 0
fi

if [[ ! -f /snowflake/session/token ]] || [[ -z "${SNOWFLAKE_ACCOUNT:-}" ]]; then
  exit 0
fi

# Snowflake CLI ~/.snowflake/connections.toml
export HOME="$RSTUDIO_HOME"
sh /usr/local/bin/setup-snow-default-connection.sh

# ODBC DSN for R: DBI::dbConnect(odbc::odbc(), "SnowflakeSPCS")
# For OAuth (SPCS): the driver requires `TOKEN` in the ODBC connection settings.
# We read the SPCS OAuth token from /snowflake/session/token at container start.
SERVER="${SNOWFLAKE_HOST}"
if [[ -z "$SERVER" ]]; then
  SERVER="${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com"
fi

ODBC_INI="${RSTUDIO_HOME}/.odbc.ini"
umask 077
{
  echo "[SnowflakeSPCS]"
  echo "Driver = SnowflakeDSIIDriver"
  echo "Server = ${SERVER}"
  [[ -n "${SNOWFLAKE_DATABASE:-}" ]] && echo "Database = ${SNOWFLAKE_DATABASE}"
  [[ -n "${SNOWFLAKE_SCHEMA:-}" ]] && echo "Schema = ${SNOWFLAKE_SCHEMA}"
  [[ -n "${SNOWFLAKE_WAREHOUSE:-}" ]] && echo "Warehouse = ${SNOWFLAKE_WAREHOUSE}"
  [[ -n "${SNOWFLAKE_ROLE:-}" ]] && echo "Role = ${SNOWFLAKE_ROLE}"
  [[ -n "${SNOWFLAKE_USER:-}" ]] && echo "UID = ${SNOWFLAKE_USER}"
  echo "Authenticator = oauth"
  # Token file may end with a trailing newline; strip it for the DSN value.
  TOKEN_VALUE="$(tr -d '\n' < /snowflake/session/token)"
  echo "TOKEN = ${TOKEN_VALUE}"
} > "$ODBC_INI"

chown -R rstudio:rstudio "${RSTUDIO_HOME}/.snowflake" "$ODBC_INI" 2>/dev/null || true
