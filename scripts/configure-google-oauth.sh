#!/usr/bin/env bash
set -euo pipefail

# Interactive configuration for the OpenList API's Google OAuth client.
# Run in DevSpace, where the Cloudflare authentication environment is already available.
# Values are never passed as command-line arguments or written into the repository.

worker_name='fyzure-openlist-oauth'
if ! command -v wrangler >/dev/null 2>&1; then
  echo 'Wrangler is not installed in this environment.' >&2
  exit 1
fi

if ! [[ -t 0 ]]; then
  echo 'Open an interactive DevSpace terminal before running this script.' >&2
  exit 1
fi

# Validate Cloudflare authentication before prompting for any credentials.
# SSH login shells may not inherit the DevSpace-injected API token.
if ! wrangler whoami >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Cloudflare authentication is not available in this shell.
Use an authenticated DevSpace terminal or add googleui_key through the
Cloudflare Dashboard > Workers & Pages > fyzure-openlist-oauth >
Settings > Variables and Secrets.
No OAuth client credentials were requested or uploaded.
EOF
  exit 2
fi

printf 'Configuring OAuth client secrets for Cloudflare Worker: %s\n' "$worker_name"
printf 'Google Web client redirect URI: %s\n' 'https://oauth-api.fyzure.fyi/googleui/callback'
printf 'Use the OpenList-APIPages-Web client, not RS-rclone-Desktop.\n'

read -r -p 'Paste Google Web Client ID: ' oauth_client_id
if [[ "$oauth_client_id" != *.apps.googleusercontent.com ]]; then
  echo 'Invalid client ID format; nothing was uploaded.' >&2
  exit 1
fi

read -r -s -p 'Paste Google Web Client Secret (hidden): ' oauth_client_secret
printf '\n'
if [[ -z "$oauth_client_secret" ]]; then
  echo 'Empty client secret; nothing was uploaded.' >&2
  exit 1
fi

printf '%s' "$oauth_client_id" | wrangler secret put googleui_uid --name "$worker_name" >/dev/null
printf 'Client ID configured.\n'
printf '%s' "$oauth_client_secret" | wrangler secret put googleui_key --name "$worker_name" >/dev/null
unset oauth_client_id oauth_client_secret
printf 'Client secret configured. Cloudflare Worker is ready for an OAuth consent flow.\n'
