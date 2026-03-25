#!/usr/bin/with-contenv bash

# ShinyProxy injects SHINYPROXY_PUBLIC_PATH (see shinyproxy.io SpEL / runtime-values).
echo "public path: $SHINYPROXY_PUBLIC_PATH"

if [[ -n "${SHINYPROXY_PUBLIC_PATH:-}" ]]; then
  echo "Set www-root-path to $SHINYPROXY_PUBLIC_PATH"
  echo "www-root-path=$SHINYPROXY_PUBLIC_PATH" >> /etc/rstudio/rserver.conf
else
  echo "Not setting www-root-path (SHINYPROXY_PUBLIC_PATH not set)"
fi
