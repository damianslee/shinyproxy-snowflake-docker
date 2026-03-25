# showdatabases2.R
# Option B: Read the SPCS OAuth token file inside R, then build the ODBC
# connection string with TOKEN=... (some Snowflake ODBC driver versions require TOKEN,
# not token_file_path).

suppressPackageStartupMessages({
  library(DBI)
  library(odbc)
})

token_path <- "/snowflake/session/token"
if (!file.exists(token_path)) {
  stop(sprintf("Token file not found at %s", token_path))
}

token <- trimws(readLines(token_path, warn = FALSE))
if (identical(token, "") || is.na(token)) {
  stop("Token file was empty")
}

account  <- Sys.getenv("SNOWFLAKE_ACCOUNT", unset = "")
host     <- Sys.getenv("SNOWFLAKE_HOST", unset = "")
database <- Sys.getenv("SNOWFLAKE_DATABASE", unset = "")
schema   <- Sys.getenv("SNOWFLAKE_SCHEMA", unset = "")
warehouse <- Sys.getenv("SNOWFLAKE_WAREHOUSE", unset = "")
role     <- Sys.getenv("SNOWFLAKE_ROLE", unset = "")
uid      <- Sys.getenv("SNOWFLAKE_USER", unset = "") # optional; may not be set in your instance

if (account == "") stop("SNOWFLAKE_ACCOUNT env var not set")
if (host == "") host <- paste0(account, ".snowflakecomputing.com")

parts <- c(
  "Driver=SnowflakeDSIIDriver",
  paste0("Server=", host),
  "Authenticator=oauth",
  paste0("TOKEN=", token)
)
if (database != "") parts <- c(parts, paste0("Database=", database))
if (schema != "") parts <- c(parts, paste0("Schema=", schema))
if (warehouse != "") parts <- c(parts, paste0("Warehouse=", warehouse))
if (role != "") parts <- c(parts, paste0("Role=", role))
if (uid != "") parts <- c(parts, paste0("UID=", uid))

conn_str <- paste(parts, collapse = ";")

cat("=== ODBC drivers ===\n")
print(odbcListDrivers())

cat("\n=== Connecting with TOKEN read from token file ===\n")
cat(sprintf("Server=%s\nDatabase=%s\nSchema=%s\nWarehouse=%s\nRole=%s\n",
            host, database, schema, warehouse, role))

con <- dbConnect(odbc::odbc(), .connection_string = conn_str, timeout = 10)
on.exit(dbDisconnect(con), add = TRUE)

cat("\n=== SHOW DATABASES ===\n")
res <- dbGetQuery(con, "SHOW DATABASES")
print(res)

