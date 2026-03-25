FROM rocker/rstudio:latest

# NB: this file is only used by rocker if the env var DISABLE_AUTH: true is specified in the application.yml
RUN echo "www-frame-origin=same" >> /etc/rstudio/disable_auth_rserver.conf
RUN echo "www-verify-user-agent=0" >> /etc/rstudio/disable_auth_rserver.conf

COPY 03_setup_root_path.sh /etc/cont-init.d/03_setup_root_path.sh
RUN chmod +x /etc/cont-init.d/03_setup_root_path.sh && \
    sed -i 's/\r$//' /etc/cont-init.d/03_setup_root_path.sh

# Snowflake CLI + ODBC driver + R packages (DBI/odbc/dbplyr) for SPCS default connection
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    unixodbc \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# nanodbc/ODBC expects libodbcinst.so.1, but the base package provides .so.2 only.
RUN ln -sf /usr/lib/x86_64-linux-gnu/libodbcinst.so.2 /usr/lib/x86_64-linux-gnu/libodbcinst.so.1

ARG SNOWFLAKE_CLI_VERSION=3.15.0
RUN wget -q "https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_x86_64/${SNOWFLAKE_CLI_VERSION}/snowflake-cli-${SNOWFLAKE_CLI_VERSION}.x86_64.deb" -O /tmp/snowflake-cli.deb \
    && (dpkg -i /tmp/snowflake-cli.deb || true) \
    && apt-get update && apt-get install -f -y --no-install-recommends \
    && rm /tmp/snowflake-cli.deb \
    && rm -rf /var/lib/apt/lists/*

ARG SNOWFLAKE_ODBC_VERSION=3.15.0
RUN wget -q "https://sfc-repo.snowflakecomputing.com/odbc/linux/${SNOWFLAKE_ODBC_VERSION}/snowflake-odbc-${SNOWFLAKE_ODBC_VERSION}.x86_64.deb" -O /tmp/snowflake-odbc.deb \
    && (dpkg -i /tmp/snowflake-odbc.deb || true) \
    && apt-get update && apt-get install -f -y --no-install-recommends \
    && rm /tmp/snowflake-odbc.deb \
    && rm -rf /var/lib/apt/lists/*

COPY setup-snow-default-connection.sh /usr/local/bin/setup-snow-default-connection.sh
RUN sed -i 's/\r$//' /usr/local/bin/setup-snow-default-connection.sh \
    && chmod +x /usr/local/bin/setup-snow-default-connection.sh

COPY 04_setup_snowflake_rstudio.sh /etc/cont-init.d/04_setup_snowflake_rstudio.sh
RUN chmod +x /etc/cont-init.d/04_setup_snowflake_rstudio.sh \
    && sed -i 's/\r$//' /etc/cont-init.d/04_setup_snowflake_rstudio.sh

RUN echo '[ -f /usr/local/bin/setup-snow-default-connection.sh ] && . /usr/local/bin/setup-snow-default-connection.sh' > /etc/profile.d/snowflake-connection.sh \
    && chmod +x /etc/profile.d/snowflake-connection.sh

# R: DBI + odbc (Snowflake via ODBC)
# `--no-test-load` avoids the expensive "try loading installed packages" phase during Docker builds.
RUN Rscript -e 'install.packages(c("DBI","odbc"), repos="https://cloud.r-project.org", Ncpus=2, INSTALL_opts="--no-test-load")'

# Example R script to test Snowflake connectivity from within RStudio.
COPY showdatabases.R /home/rstudio/showdatabases.R
RUN chmod 644 /home/rstudio/showdatabases.R && chown -R rstudio:rstudio /home/rstudio/showdatabases.R || true

# Option B: specify token directly in R and pass TOKEN=... in the ODBC connection string.
COPY showdatabases2.R /home/rstudio/showdatabases2.R
RUN chmod 644 /home/rstudio/showdatabases2.R && chown -R rstudio:rstudio /home/rstudio/showdatabases2.R || true

# By default RStudio does not give access to all environment variables defined in the container (e.g. using ShinyProxy).
# If you add a script, use a name after 04_setup_snowflake_rstudio (e.g. 05_copy_env.sh).
#ADD 04_copy_env.sh /etc/cont-init.d/05_copy_env.sh

# By default RStudio does not read /etc/profile when starting an R session.
# Uncomment the next two lines to change this behavior.
#COPY rsession-with-profile /usr/local/bin/rsession-with-profile
#RUN echo "rsession-path=/usr/local/bin/rsession-with-profile" >> /etc/rstudio/disable_auth_rserver.conf
