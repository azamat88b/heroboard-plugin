#!/usr/bin/env bash
# Continuous presence heartbeat (HB-235). Backgrounds a loop that pings Heroboard every
# ~60s while the Claude Code session is open, so effort accrues even when you're watching
# a long agent run (not typing). 0 tokens.
#
# OPT-IN: disabled unless HEROBOARD_PRESENCE_TICKER=1 — a default-on ticker would keep you
# "online" while idle and inflate effort. Event hooks (prompt/edit) stay the accurate default.
#
# Lifecycle: SessionStart → start, SessionEnd → stop (via PID file). A hard 12h cap means
# even an orphaned loop dies on its own.
PIDFILE="${TMPDIR:-/tmp}/heroboard-presence.pid"

stop() {
  [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" >/dev/null 2>&1
  rm -f "$PIDFILE"
}

start() {
  [ "${HEROBOARD_PRESENCE_TICKER:-}" = "1" ] || exit 0
  key="${CLAUDE_PLUGIN_OPTION_api_key:-${HEROBOARD_API_KEY:-}}"  # userConfig (HB-244), legacy env fallback
  [ -z "$key" ] && exit 0
  stop  # avoid duplicate loops
  ( i=0
    while [ "$i" -lt 720 ]; do            # 720 * 60s = 12h safety cap
      curl -s -m 3 -X POST "https://v2.heroboard.app/api/heartbeat" \
        -H "X-Api-Key: ${key}" -H "Content-Type: application/json" \
        -d '{"kind":"heartbeat"}' >/dev/null 2>&1
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
