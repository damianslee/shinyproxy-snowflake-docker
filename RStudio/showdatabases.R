# showdatabases.R
# Test Snowflake connection from R via ODBC using the DSN configured by the container:
# DSN name: "SnowflakeSPCS"

suppressPackageStartupMessages({
  library(DBI)
  library(odbc)
})

cat("ODBC drivers:\n")
print(odbcListDrivers())

cat("\nODBC data sources:\n")
print(odbcListDataSources())

token_path <- "/snowflake/session/token"
if (!file.exists(token_path)) {
  warning(sprintf("Token file not found at %s. In SPCS this should exist when the service is running.", token_path))
}

con <- NULL
on.exit({
  if (!is.null(con)) {
    try(dbDisconnect(con), silent = TRUE)
  }
}, add = TRUE)

con <- dbConnect(odbc::odbc(), "SnowflakeSPCS", timeout = 10)

cat("\nSHOW DATABASES result:\n")
res <- dbGetQuery(con, "SHOW DATABASES")
print(res)

