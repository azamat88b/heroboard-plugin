#!/usr/bin/env bash
# Heroboard effort heartbeat (HB-220/221/222). Fire-and-forget: never blocks the prompt,
# never errors the hook, costs zero tokens (plain HTTP, no model call).
#   usage: heartbeat.sh <kind>      kind = "heartbeat" (human/Monkey) | "code" (agent)
# The API key comes from the plugin's userConfig (HB-244): Claude Code prompts for it once,
# stores it in the system keychain, and exports it to plugin hooks as CLAUDE_PLUGIN_OPTION_api_key
# — no shell `export`, works in new windows / GUI editors / Windows. No key → silent no-op.
kind="${1:-heartbeat}"
key="${CLAUDE_PLUGIN_OPTION_api_key:-${HEROBOARD_API_KEY:-}}"  # userConfig, fall back to legacy env
[ -z "$key" ] && exit 0
curl -s -m 3 -X POST "https://v2.heroboard.app/api/heartbeat" \
  -H "X-Api-Key: ${key}" \
  -H "Content-Type: application/json" \
  -d "{\"kind\":\"${kind}\"}" >/dev/null 2>&1 &
exit 0
