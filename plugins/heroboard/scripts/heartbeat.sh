#!/usr/bin/env bash
# Heroboard effort heartbeat (HB-220/221/222). Fire-and-forget: never blocks the prompt,
# never errors the hook, costs zero tokens (plain HTTP, no model call).
#   usage: heartbeat.sh <kind>      kind = "heartbeat" (human/Monkey) | "code" (agent)
# The API key comes from the plugin's userConfig → keychain (HB-244), exported to hooks as
# CLAUDE_PLUGIN_OPTION_api_key in terminal sessions; agent-mode (app) sessions fall back to the
# cached ~/.heroboard/key (see _key.sh, HB-252). No key → silent no-op.
kind="${1:-heartbeat}"
. "$(cd "$(dirname "$0")" && pwd)/_key.sh"
key="$(hb_resolve_key)"
[ -z "$key" ] && exit 0
# Repo of the working dir → the server maps it to a project so this time accrues to the right
# workspace (HB-250). git absent / not a repo → omit, server leaves the event unattributed.
repo="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" config --get remote.origin.url 2>/dev/null)"
if [ -n "$repo" ]; then
  payload="{\"kind\":\"${kind}\",\"repo\":\"${repo}\"}"
else
  payload="{\"kind\":\"${kind}\"}"
fi
curl -s -m 3 -X POST "https://v2.heroboard.app/api/heartbeat" \
  -H "X-Api-Key: ${key}" \
  -H "Content-Type: application/json" \
  -d "$payload" >/dev/null 2>&1 &
exit 0
