#!/usr/bin/env bash
# Shared Heroboard API-key resolver (HB-252). Sourced by heartbeat.sh / presence-ticker.sh.
#
# The key lives in the plugin's userConfig → system keychain (HB-244). Claude Code exports
# it to hooks as CLAUDE_PLUGIN_OPTION_api_key — but ONLY in terminal CLI sessions. In
# agent-mode (the Claude desktop/web app) the userConfig key reaches the MCP server (via
# ${user_config.api_key} substitution) yet is NOT exported into hook env, so the shell hooks
# would silently no-op and Agent time wouldn't accrue.
#
# Bridge: a terminal session (which HAS the key in env) caches it to ~/.heroboard/key (0600);
# agent-mode sessions, lacking the env var, fall back to reading that file. The plaintext key
# on disk is the deliberate trade-off for app-session effort tracking. Best-effort throughout:
# a hook must never block or fail, so every fs op is guarded and silent.
HB_KEYFILE="${HOME}/.heroboard/key"

# Print the resolved key (empty if none). Side effect: when the env key is present, cache it.
hb_resolve_key() {
  local k="${CLAUDE_PLUGIN_OPTION_api_key:-}"
  if [ -n "$k" ]; then
    # cache for env-less (agent-mode) sessions, only when changed, perms locked to the user
    if [ "$(cat "$HB_KEYFILE" 2>/dev/null)" != "$k" ]; then
      mkdir -p "${HOME}/.heroboard" 2>/dev/null && ( umask 177; printf '%s' "$k" > "$HB_KEYFILE" ) 2>/dev/null
    fi
    printf '%s' "$k"
    return 0
  fi
  cat "$HB_KEYFILE" 2>/dev/null
}
