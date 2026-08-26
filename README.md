# Garmin MCP → Claude (phone + web) via Render

Hosts [Taxuspt/garmin_mcp](https://github.com/Taxuspt/garmin_mcp) as a remote MCP
server so it can be added to claude.ai as a custom connector and used from any
device, including the mobile app.

The MCP server has **no authentication of its own**. A Caddy reverse proxy sits
in front and only forwards requests to `/<MCP_SECRET>/mcp`; everything else 404s.
Over HTTPS that secret path is the shared key.

## What's in here
- `Dockerfile` — Garmin MCP server + Caddy in one image
- `Caddyfile` — gates access on the `$MCP_SECRET` path prefix
- `start.sh` — installs the token file, launches both processes
- `render.yaml` — Render blueprint (generates `MCP_SECRET`, sets health check)

## Deploy (one time)

### 1. Push this repo to GitHub (private recommended)
```bash
cd ~/garmin-mcp-deploy
git init && git add -A && git commit -m "Garmin MCP remote host"
gh repo create garmin-mcp-deploy --private --source=. --push   # needs: gh auth login
```

### 2. Create the Render service
- Render dashboard → **New + → Blueprint** → pick this repo → **Apply**.
- This creates a Docker web service and auto-generates `MCP_SECRET`.

### 3. Add the Garmin token as a Secret File
The server needs your saved OAuth token file. Copy its contents:
```bash
cat ~/.garminconnect/garmin_tokens.json | pbcopy   # now in your clipboard
```
In Render → the service → **Environment → Secret Files → Add Secret File**:
- **Filename / mount path:** `/etc/secrets/garmin_tokens.json`
- **Contents:** paste from clipboard
Save → the service redeploys.

### 4. Build your connector URL
- In Render → **Environment**, copy the generated **`MCP_SECRET`** value.
- Your service URL is `https://<service-name>.onrender.com`.
- Connector URL =
  ```
  https://<service-name>.onrender.com/<MCP_SECRET>/mcp
  ```

### 5. Add it to Claude
claude.ai (web) → **Settings → Connectors → Add custom connector** → paste the
connector URL from step 4 → save. It syncs to the **mobile app** automatically.
Then enable it in a chat and ask away.

## Maintenance
- Garmin tokens last ~6 months. To refresh, re-run locally:
  ```bash
  uvx --python 3.12 --from git+https://github.com/Taxuspt/garmin_mcp garmin-mcp-auth
  ```
  then update the Render Secret File (step 3) with the new
  `~/.garminconnect/garmin_tokens.json`.
- Rotating your Garmin password may invalidate the tokens — if data stops
  loading, re-auth as above.

## Security notes
- Anyone with the full connector URL can read your Garmin data — treat it like a
  password. It lives only in Render (generated) and in your Claude connector.
- The token file is a Render Secret File, never committed (`.gitignore` covers it).
