# Builder: compile Snowflake CLI and install Cortex Code (build tools not present in final image)
FROM tsl0922/ttyd:alpine AS builder

RUN apk add --no-cache python3 py3-pip curl build-base python3-dev
RUN pip3 install --break-system-packages --target /build/snowflake-cli snowflake-cli

# Cortex Code CLI: install to /root/.local/bin (script may fail on Alpine/musl or if non-interactive)
ENV HOME=/root
RUN mkdir -p /root/.local/bin && \
    (curl -LsSf https://ai.snowflake.com/static/cc-scripts/install.sh | sh || true)

# Final image: minimal runtime, no compilers or build deps
FROM tsl0922/ttyd:alpine

RUN apk add --no-cache python3 curl

COPY --from=builder /build/snowflake-cli /opt/snowflake-cli
COPY --from=builder /root/.local/bin /root/.local/bin

ENV PYTHONPATH=/opt/snowflake-cli
ENV PATH="/root/.local/bin:/opt/snowflake-cli/bin:$PATH"

COPY setup-snow-default-connection.sh /usr/local/bin/setup-snow-default-connection.sh
RUN sed -i 's/\r$//' /usr/local/bin/setup-snow-default-connection.sh && chmod +x /usr/local/bin/setup-snow-default-connection.sh
RUN echo '[ -f /usr/local/bin/setup-snow-default-connection.sh ] && . /usr/local/bin/setup-snow-default-connection.sh' >> /root/.bashrc

RUN snow --version && (cortex --version 2>/dev/null || true)
