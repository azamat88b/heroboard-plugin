#!/usr/bin/env bash
# Shared Heroboard API-key resolver (HB-252). Sourced by heartbeat.sh / presence-ticker.sh.
#
# The key lives in the plugin's userConfig → system keychain (HB-244). Claude Code exports
# it to hooks as CLAUDE_PLUGIN_OPTION_api_key — but ONLY in terminal CLI sessions. In
# agent-mode (the Claude desktop/web app) the userConfig key reaches the MCP server (via
# ${user_config.api_key} substitution) yet is NOT exported into hook env, so the shell hooks
# would silently no-op and Agent time wouldn't accrue.
#
# Bridge: a terminal session (which HAS the key in env) caches it to a dedicated config file
# (0600); agent-mode sessions, lacking the env var, fall back to reading that file. The
# plaintext key on disk is the deliberate trade-off for app-session effort tracking. Best-effort
# throughout: a hook must never block or fail, so every fs op is guarded and silent.
HB_CONFDIR="${XDG_CONFIG_HOME:-$HOME/.config}/heroboard-plugin"
HB_KEYFILE="$HB_CONFDIR/key"

# Opt-in debug log (HB-254): hooks are otherwise invisible — you can't tell if they fire,
# resolve a key, or what the server replies. Enable by `export HEROBOARD_DEBUG=1` OR by
# `touch ~/.config/heroboard-plugin/debug`, then tail ~/.config/heroboard-plugin/debug.log.
# Off by default, best-effort, never fails the hook. Logs never contain the key itself.
HB_LOGFILE="$HB_CONFDIR/debug.log"
hb_log() {
  case "${HEROBOARD_DEBUG:-}" in
    1|true|on|yes) ;;
    *) [ -f "$HB_CONFDIR/debug" ] || return 0 ;;
  esac
  mkdir -p "$HB_CONFDIR" 2>/dev/null
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "${HB_TAG:-hook}" "$*" >> "$HB_LOGFILE" 2>/dev/null
}

# Print the resolved key (empty if none). Side effect: when the env key is present, cache it.
hb_resolve_key() {
  local k="${CLAUDE_PLUGIN_OPTION_api_key:-}"
  if [ -n "$k" ]; then
    # cache for env-less (agent-mode) sessions, only when changed, perms locked to the user
    if [ "$(cat "$HB_KEYFILE" 2>/dev/null)" != "$k" ]; then
      mkdir -p "$(dirname "$HB_KEYFILE")" 2>/dev/null && ( umask 177; printf '%s' "$k" > "$HB_KEYFILE" ) 2>/dev/null
    fi
    hb_log "key resolved from env (len=${#k})"
    printf '%s' "$k"
    return 0
  fi
  local fk; fk="$(cat "$HB_KEYFILE" 2>/dev/null)"
  if [ -n "$fk" ]; then hb_log "key resolved from file (len=${#fk})"; else hb_log "NO key (env empty, no keyfile)"; fi
  printf '%s' "$fk"
}
