# Code-Server (Snowflake + Cortex Code)

Custom code-server image based on `linuxserver/code-server`, focused on **Snowflake CLI**, **Cortex Code CLI**, and **default Snowflake connection** setup. **No VS Code extensions are pre-installed**—install from the Extensions view or VSIX if needed.

## Ports

- **8443** — code-server (default for [linuxserver/code-server](https://github.com/linuxserver/docker-code-server); HTTPS with self-signed cert from the base image).

ShinyProxy should target this port in `application.yml` (`port: 8443` for the `code_server` spec).

## What’s included

- **snowflake-cli** (`.deb` from Snowflake)
- **cortex** in `/usr/local/bin` (Snowflake Cortex Code install script)
- **`snowflake-connector-python`** (pip) for Python scripts in the terminal
- **Python 3** + pip/venv
- **`setup-snow-default-connection.sh`** sourced from `/etc/profile.d/snowflake-connection.sh` for login shells (see `setup-snow-default-connection.sh` for required env vars)

## Build and push

From the repo root:

```bash
docker build --platform linux/amd64 -t <your-registry>/code-server:latest ./CodeServer
docker push <your-registry>/code-server:latest
```

See `snowflake_docker.bat` for the full Snowflake registry workflow.
