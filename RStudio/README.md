# Running RStudio inside ShinyProxy

**RStudio version**: 2025.05.1 Build 513
**R Version**: 4.5.1

- [Click here for a version using R 3.6.0](https://github.com/openanalytics/shinyproxy-rstudio-ide-demo/tree/1.2.1335__3.6.0)
- [Click here for a version using R 4.0.4](https://github.com/openanalytics/shinyproxy-rstudio-ide-demo/tree/1.4.1106__4.0.4)
- [Click here for a version using R 4.1.2](https://github.com/openanalytics/shinyproxy-rstudio-ide-demo/tree/2021.09.2_382__4.1.2)
- [Click here for a version using R 4.3.1](https://github.com/openanalytics/shinyproxy-rstudio-ide-demo/tree/2023.06.0_421__4.3.1)

[Screenshot](#screenshot)

This repository explains how to run RStudio in ShinyProxy.
RStudio 4.3.1 and later requires at least ShinyProxy 2.5.0.

## Building the Docker image

To pull the image made in this repository from Docker Hub, use

```bash
sudo docker pull openanalytics/shinyproxy-rstudio-ide-demo:2025.05.1_513__4.5.1
```

The relevant Docker Hub repository can be found at [https://hub.docker.com/r/openanalytics/shinyproxy-rstudio-ide-demo](https://hub.docker.com/r/openanalytics/shinyproxy-rstudio-ide-demo)

To build the image from the Dockerfile, navigate into the root directory of this repository and run

```bash
sudo docker build -t openanalytics/shinyproxy-rstudio-ide-demo:2025.05.1_513__4.5.1 .
```

## ShinyProxy Configuration

For deployment on ShinyProxy the environment variable `DISABLE_AUTH` must be set to `true`, and the port of the container must be configured to **8787**. ShinyProxy injects **`SHINYPROXY_PUBLIC_PATH`** into the container automatically ([runtime-values / SpEL](https://www.shinyproxy.io/documentation/spel/)); `03_setup_root_path.sh` maps it to RStudio’s `www-root-path`.

```yaml
proxy:
  specs:
    - id: rstudio
      container-image: openanalytics/shinyproxy-rstudio-ide-demo:2025.05.1_513__4.5.1
      container-env:
        DISABLE_AUTH: true
      port: 8787
```

Another useful option is to mount volume per user, e.g.:

```yaml
    container-volumes: [ "/tmp/#{proxy.userId}:/home/rstudio" ]
```

Here `/home/rstudio` is used inside the container since "rstudio" is the default username in `rocker/rstudio` image.
If desired, this can be changed by setting `USER` environment variable in the application specs as follows:

```yaml
proxy:
  specs:
    - id: rstudio
      container-image: openanalytics/shinyproxy-rstudio-ide-demo:2025.05.1_513__4.5.1
      container-env:
        DISABLE_AUTH: true
        USER: "#{proxy.userId}"
      port: 8787
      container-volumes: [ "/tmp/#{proxy.userId}:/home/#{proxy.userId}" ]
```

## Snowflake CLI, ODBC, and R

The image includes:

- **Snowflake CLI** (`snowflake` command) — same `.deb` install pattern as the CodeServer image.
- **Snowflake ODBC driver** + **unixODBC** — for database connections from R.
- **R packages**: [`DBI`](https://cran.r-project.org/package=DBI) and [`odbc`](https://cran.r-project.org/package=odbc) (ODBC connectivity from R).

### SPCS default connection

When the service runs in **Snowflake SPCS** with `/snowflake/session/token` and env vars such as `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_HOST`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`, etc., **`04_setup_snowflake_rstudio.sh`** (cont-init) configures:

| What | Where |
|------|--------|
| Snowflake CLI `[default]` | `/home/rstudio/.snowflake/connections.toml` |
| ODBC DSN **`SnowflakeSPCS`** | `/home/rstudio/.odbc.ini` |

### Build performance note

If you build `RStudio` on an ARM host while forcing `linux/amd64` (for SP CS amd64-only environments), Docker uses emulation. That makes `R` package installation significantly slower because many CRAN packages still compile/build during `install.packages()`.

In R or the RStudio **Connections** pane, connect with:

```r
library(DBI)
con <- dbConnect(odbc::odbc(), "SnowflakeSPCS", timeout = 10)
dbGetQuery(con, "SELECT 1")
dbDisconnect(con)
```

Optional env var **`SNOWFLAKE_USER`** is written to the DSN as `UID` if the driver requires an explicit user (see [Snowflake ODBC parameters](https://docs.snowflake.com/en/developer-guide/odbc/odbc-parameters)).

Terminal sessions also source **`/etc/profile.d/snowflake-connection.sh`**, which runs `setup-snow-default-connection.sh` for the current user’s `HOME` (so `snow sql` can use the default connection when the token is present).

**Note:** Image is **x86_64** Snowflake `.deb` packages. For **arm64**, adjust download URLs or install paths per Snowflake docs.

### Other R packages

For Snowflake you do **not** need a separate proprietary R package if you use **ODBC**. Alternatives (not installed by default):

- **JDBC** + `RJDBC` — possible but heavier (Java + JDBC jar).
- **`snowflake`**-named CRAN packages — none are official first-party Snowflake R drivers; ODBC or JDBC are the supported paths.

## Optional features

Check the `Dockerfile` for instructions on how to change the default behavior of
the Docker image to:

- use all environment variables in RStudio
- read `/etc/profile` when starting an R session

## Screenshot

![RStudio](.github/screenshots/rstudio.png)

**(c) Copyright Open Analytics NV, 2019-2025.**
