#!/usr/bin/env bash
# Continuous presence heartbeat (HB-235). Backgrounds a loop that pings Heroboard every
# ~60s while the Claude Code session is open, so effort accrues even when you're watching
# a long agent run (not typing). 0 tokens.
#
# ON BY DEFAULT (HB-247): controlled by the plugin's userConfig toggle "presence_ticker"
# (exported as CLAUDE_PLUGIN_OPTION_presence_ticker, default true). Unlike the old env flag,
# a userConfig toggle is present in every session — new windows, GUI editors, Windows — so
# re-enabling gives continuous time with no per-shell gaps. Turn the toggle off to count only
# prompt/edit events. Legacy HEROBOARD_PRESENCE_TICKER env is still honored as a fallback.
#
# Lifecycle: SessionStart → start, SessionEnd → stop (via PID file). A hard 12h cap means
# even an orphaned loop dies on its own.
PIDFILE="${TMPDIR:-/tmp}/heroboard-presence.pid"

stop() {
  [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" >/dev/null 2>&1
  rm -f "$PIDFILE"
}

start() {
  . "$(cd "$(dirname "$0")" && pwd)/_key.sh"  # keychain key, with ~/.config/heroboard-plugin/key fallback (HB-252)
  key="$(hb_resolve_key)"
  # Required config: with no api_key NOTHING accrues — this ticker AND the per-prompt/-edit
  # heartbeat hooks all silently no-op. Claude Code lets the plugin be enabled without the
  # required key, so instead of doing nothing we surface a loud, non-blocking warning once
  # per session via the SessionStart hook's `systemMessage` (shown to the user; exit 0 never
  # blocks startup). SessionStart is the single warning surface — the heartbeat hook stays
  # quiet so the same notice isn't repeated on every prompt/edit (HB-248).
  if [ -z "$key" ]; then
    printf '%s\n' '{"systemMessage":"Heroboard: required config missing — api_key. Effort tracking is OFF until it is set. Configure it via /plugin → heroboard → Configure (paste your hb_… key), then start a new session. In the Claude app, also run the plugin in a terminal once so the hooks can read the key."}'
    exit 0
  fi
  # presence ticker is default-on unless the toggle is explicitly falsey (HB-247)
  toggle="${CLAUDE_PLUGIN_OPTION_presence_ticker:-${CLAUDE_PLUGIN_OPTION_PRESENCE_TICKER:-${HEROBOARD_PRESENCE_TICKER:-1}}}"
  case "$(printf '%s' "$toggle" | tr '[:upper:]' '[:lower:]')" in
    0|false|off|no|"") exit 0 ;;
  esac
  # Repo of the session's working dir, captured once → the server maps it to a project so
  # presence time accrues to the right workspace (HB-250). Not a repo → unattributed.
  repo="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" config --get remote.origin.url 2>/dev/null)"
  if [ -n "$repo" ]; then
    payload="{\"kind\":\"heartbeat\",\"repo\":\"${repo}\"}"
  else
    payload='{"kind":"heartbeat"}'
  fi
  stop  # avoid duplicate loops
  ( i=0
    while [ "$i" -lt 720 ]; do            # 720 * 60s = 12h safety cap
      curl -s -m 3 -X POST "https://v2.heroboard.app/api/heartbeat" \
        -H "X-Api-Key: ${key}" -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1
      i=$((i + 1)); sleep 60
    done
    rm -f "$PIDFILE" ) >/dev/null 2>&1 &
  echo $! > "$PIDFILE"
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
esac
exit 0
