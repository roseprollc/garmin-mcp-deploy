#!/usr/bin/env bash
set -euo pipefail

# Refuse to start unconfigured — an empty MCP_SECRET would expose /mcp openly.
: "${PORT:?PORT must be set (Render provides this automatically)}"
: "${MCP_SECRET:?MCP_SECRET must be set — it is the secret in the connector URL}"

# Put the Garmin OAuth token file where the server expects it.
mkdir -p /root/.garminconnect
if [ -f /etc/secrets/garmin_tokens.json ]; then
	cp /etc/secrets/garmin_tokens.json /root/.garminconnect/garmin_tokens.json
	chmod 600 /root/.garminconnect/garmin_tokens.json
	echo "Garmin token file installed."
else
	echo "FATAL: /etc/secrets/garmin_tokens.json not found — add it as a Render Secret File." >&2
	exit 1
fi

# Start the Garmin MCP server (HTTP on localhost only; Caddy fronts it).
garmin-mcp &
GARMIN_PID=$!

# If the server dies, take the container down with it.
trap 'kill "$GARMIN_PID" 2>/dev/null || true' EXIT

# Caddy in the foreground: binds $PORT, gates on $MCP_SECRET.
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
