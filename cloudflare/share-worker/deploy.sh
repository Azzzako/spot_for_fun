#!/usr/bin/env bash
# Deploys the share-link Worker, passing the Supabase URL and publishable
# key from the app's .env so they never get committed.
set -euo pipefail
cd "$(dirname "$0")"

env_file="../../.env"
read_env() { grep -E "^$1=" "$env_file" | head -1 | cut -d= -f2- | xargs; }

url="$(read_env SUPABASE_URL)"
key="$(read_env SUPABASE_PUBLISHABLE_KEY)"
if [[ -z "$url" || -z "$key" ]]; then
  echo "Faltan SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY en $env_file" >&2
  exit 1
fi

npx --yes wrangler@4 deploy \
  --var "SUPABASE_URL:$url" \
  --var "SUPABASE_PUBLISHABLE_KEY:$key"
