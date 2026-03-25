# Custom code-server with Snowflake CLI, Cortex Code CLI, and default connection setup.
# No VS Code extensions are pre-installed. code-server listens on the base image default port (8443).
# Base: linuxserver/code-server (Ubuntu Noble 24.04; runtime user has HOME=/config).
# Upstream: https://github.com/linuxserver/docker-code-server
FROM linuxserver/code-server:latest

# Install system deps (Python for optional scripting). Base is ghcr.io/linuxserver/baseimage-ubuntu:noble.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Snowflake Python connector (terminal / scripts; no Jupyter kernel or bundled editor extensions)
RUN pip3 install --break-system-packages --no-cache-dir snowflake-connector-python

# Snowflake CLI: install from .deb (amd64)
ARG SNOWFLAKE_CLI_VERSION=3.15.0
RUN wget -q "https://sfc-repo.snowflakecomputing.com/snowflake-cli/linux_x86_64/${SNOWFLAKE_CLI_VERSION}/snowflake-cli-${SNOWFLAKE_CLI_VERSION}.x86_64.deb" -O /tmp/snowflake-cli.deb \
    && (dpkg -i /tmp/snowflake-cli.deb || true) \
    && apt-get update && apt-get install -f -y --no-install-recommends \
    && rm /tmp/snowflake-cli.deb \
    && rm -rf /var/lib/apt/lists/*

# Cortex Code CLI: install script puts binary in $HOME/.local/bin (use /root only for this RUN; do not set ENV HOME or it overrides base image HOME=/config and breaks code-server at runtime)
RUN HOME=/root mkdir -p /root/.local/bin \
    && (HOME=/root curl -LsSf https://ai.snowflake.com/static/cc-scripts/install.sh | sh || true) \
    && [ -f /root/.local/bin/cortex ] && cp /root/.local/bin/cortex /usr/local/bin/cortex && chmod +x /usr/local/bin/cortex || true

# SPCS connection setup script (sourced for all users via profile.d)
COPY setup-snow-default-connection.sh /usr/local/bin/setup-snow-default-connection.sh
RUN sed -i 's/\r$//' /usr/local/bin/setup-snow-default-connection.sh \
    && chmod +x /usr/local/bin/setup-snow-default-connection.sh

# Source connection setup for any login shell (works when HOME=/config at runtime)
RUN echo '[ -f /usr/local/bin/setup-snow-default-connection.sh ] && . /usr/local/bin/setup-snow-default-connection.sh' > /etc/profile.d/snowflake-connection.sh \
    && chmod +x /etc/profile.d/snowflake-connection.sh

# Ensure /config exists for code-server user data (UID 1000).
RUN mkdir -p /config/.local/share/code-server /config/.local/share/code-server/User \
    && chown -R 1000:1000 /config

# Ensure /config stays owned by runtime user (entrypoint may chown by PUID; 1000 is default).
RUN chown -R 1000:1000 /config

# Example Python script to test Snowflake connectivity from within code-server.
# Placed under /config/workspace so it shows up in the code-server workspace.
RUN mkdir -p /config/workspace
COPY showdatabases.py /config/workspace/showdatabases.py
RUN chmod 644 /config/workspace/showdatabases.py && chown 1000:1000 /config/workspace/showdatabases.py
