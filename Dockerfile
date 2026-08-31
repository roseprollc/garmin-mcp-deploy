# Garmin MCP server + Caddy reverse proxy in one container.
# The MCP server has NO auth of its own, so Caddy fronts it and only
# forwards requests carrying the secret path prefix ($MCP_SECRET).
FROM python:3.12-slim

# --- Caddy (static binary; no apt repo dance) ---
ARG CADDY_VERSION=2.8.4
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates git \
 && curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" -o /tmp/caddy.tgz \
 && tar -xzf /tmp/caddy.tgz -C /usr/local/bin caddy \
 && rm /tmp/caddy.tgz \
 && apt-get purge -y curl && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# --- Garmin MCP server (installed from the upstream repo) ---
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
RUN uv pip install --system "git+https://github.com/Taxuspt/garmin_mcp"

ENV PYTHONUNBUFFERED=1 \
    GARMIN_MCP_TRANSPORT=streamable-http \
    GARMIN_MCP_HOST=127.0.0.1 \
    GARMIN_MCP_PORT=8000

COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
