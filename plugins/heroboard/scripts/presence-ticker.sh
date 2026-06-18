#!/usr/bin/env bash
# Continuous presence heartbeat (HB-235). Backgrounds a loop that pings Heroboard every
# ~60s while the session is ACTIVE — i.e. you submitted a prompt within the last 5 min
# (HB-269) — so effort tracks live human presence, not just an open window. Tool-use alone
# no longer keeps it alive, so an idle/overnight session stops accruing. 0 tokens.
#
# ON BY DEFAULT (HB-247): controlled by the plugin's userConfig toggle "presence_ticker"
# (exported as CLAUDE_PLUGIN_OPTION_presence_ticker, default true). Unlike the old env flag,
# a userConfig toggle is present in every session — new windows, GUI editors, Windows — so
# re-enabling gives continuous time with no per-shell gaps. Turn the toggle off to count only
# prompt/edit events. Legacy HEROBOARD_PRESENCE_TICKER env is still honored as a fallback.
#
# Lifecycle: SessionStart → start, SessionEnd → stop (via PID file). A hard 12h cap means
# even an orphaned loop dies on its own.
. "$(cd "$(dirname "$0")" && pwd)/_key.sh"  # hb_resolve_key (key, HB-252) + hb_log (HB-258) + hb_session_id
# Per-session id (reads the hook's stdin JSON once, see _key.sh). Namespacing both state files
# by it means each concurrent session runs its own correctly-attributed ticker, and OS users
# sharing /tmp on a Linux box never collide on the pid/activity files.
HB_SID="$(hb_session_id)"
PIDFILE="${TMPDIR:-/tmp}/heroboard-presence.${HB_SID}.pid"
ACTFILE="${TMPDIR:-/tmp}/heroboard-last-activity.${HB_SID}"  # mtime bumped by heartbeat.sh on prompts (HB-269); path must match heartbeat's
IDLE_MAX=300  # stop accruing 5 min after the last human prompt
HB_TAG="presence"

stop() {
  if [ -f "$PIDFILE" ]; then hb_log "stop (pid=$(cat "$PIDFILE" 2>/dev/null))"; kill "$(cat "$PIDFILE")" >/dev/null 2>&1; fi
  rm -f "$PIDFILE"
}

start() {
  key="$(hb_resolve_key)"
  # Required config: with no api_key NOTHING accrues — this ticker AND the per-prompt/-edit
  # heartbeat hooks all silently no-op. Claude Code lets the plugin be enabled without the
  # required key, so instead of doing nothing we surface a loud, non-blocking warning once
  # per session via the SessionStart hook's `systemMessage` (shown to the user; exit 0 never
  # blocks startup). SessionStart is the single warning surface — the heartbeat hook stays
  # quiet so the same notice isn't repeated on every prompt/edit (HB-248).
  if [ -z "$key" ]; then
    hb_log "no key — surfacing warning, ticker not started"
    printf '%s\n' '{"systemMessage":"Heroboard: required config missing — api_key. Effort tracking is OFF until it is set. Configure it via /plugin → heroboard → Configure (paste your hb_… key), then start a new session. In the Claude app, also run the plugin in a terminal once so the hooks can read the key."}'
    exit 0
  fi
  # presence ticker is default-on unless the toggle is explicitly falsey (HB-247)
  toggle="${CLAUDE_PLUGIN_OPTION_presence_ticker:-${CLAUDE_PLUGIN_OPTION_PRESENCE_TICKER:-${HEROBOARD_PRESENCE_TICKER:-1}}}"
  case "$(printf '%s' "$toggle" | tr '[:upper:]' '[:lower:]')" in
    0|false|off|no|"") hb_log "disabled by toggle ($toggle)"; exit 0 ;;
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
  hb_log "start (repo=${repo:-<none>})"
  ( i=0
    while [ "$i" -lt 720 ]; do            # 720 * 60s = 12h safety cap
      # Idle gate (HB-269): only accrue while a human prompted within IDLE_MAX. The activity
      # file's mtime is bumped by heartbeat.sh on UserPromptSubmit only; stat is GNU/BSD-portable.
      last="$(stat -c %Y "$ACTFILE" 2>/dev/null || stat -f %m "$ACTFILE" 2>/dev/null || echo 0)"
      if [ "$(( $(date +%s) - last ))" -gt "$IDLE_MAX" ]; then
        hb_log "tick $i -> idle, skip"
      else
        code=$(curl -s -m 3 -o /dev/null -w '%{http_code}' -X POST "https://dev.heroboard.app/api/heartbeat" \
          -H "X-Api-Key: ${key}" -H "Content-Type: application/json" \
          -d "$payload")
        hb_log "tick $i -> HTTP ${code:-000}"
      fi
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
