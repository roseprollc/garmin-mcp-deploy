#!/usr/bin/env bash
set -euo pipefail

# Refuse to start unconfigured — an empty MCP_SECRET would expose /mcp openly.
: "${PORT:?PORT must be set (Render provides this automatically)}"
: "${MCP_SECRET:?MCP_SECRET must be set — it is the secret in the connector URL}"

# Put the Garmin OAuth token file where the server expects it.
# Prefer a base64 env var (easy to inject via the Render API); otherwise
# fall back to a mounted Secret File.
mkdir -p /root/.garminconnect
if [ -n "${GARMIN_TOKENS_B64:-}" ]; then
	echo "$GARMIN_TOKENS_B64" | base64 -d > /root/.garminconnect/garmin_tokens.json
	chmod 600 /root/.garminconnect/garmin_tokens.json
	echo "Garmin token installed from GARMIN_TOKENS_B64."
elif [ -f /etc/secrets/garmin_tokens.json ]; then
	cp /etc/secrets/garmin_tokens.json /root/.garminconnect/garmin_tokens.json
	chmod 600 /root/.garminconnect/garmin_tokens.json
	echo "Garmin token installed from Secret File."
else
	echo "FATAL: no token — set GARMIN_TOKENS_B64 or add the Secret File." >&2
	exit 1
fi

# Start the Garmin MCP server (HTTP on localhost only; Caddy fronts it).
garmin-mcp &
GARMIN_PID=$!

# If the server dies, take the container down with it.
trap 'kill "$GARMIN_PID" 2>/dev/null || true' EXIT

# Caddy in the foreground: binds $PORT, gates on $MCP_SECRET.
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
