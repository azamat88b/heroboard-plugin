#!/usr/bin/env bash
# Heroboard effort heartbeat (HB-220/221/222). Fire-and-forget: never blocks the prompt,
# never errors the hook, costs zero tokens (plain HTTP, no model call).
#   usage: heartbeat.sh <kind>      kind = "heartbeat" (human/Monkey) | "code" (agent)
# Reads the API key from $HEROBOARD_API_KEY (set once via /heroboard:login or your shell
# profile). If the key is unset we silently no-op so the hook never gets in the way.
kind="${1:-heartbeat}"
[ -z "${HEROBOARD_API_KEY:-}" ] && exit 0
curl -s -m 3 -X POST "https://v2.heroboard.app/api/heartbeat" \
  -H "X-Api-Key: ${HEROBOARD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"kind\":\"${kind}\"}" >/dev/null 2>&1 &
exit 0
