# Heroboard — Claude Code plugin

Connects your Claude Code session to [Heroboard](https://v2.heroboard.app): task tools over
MCP, effort heartbeats that turn your terminal time into XP, and `/heroboard` commands.

## What you get
- **MCP task tools** — `list_projects`, `list_tasks`, `get_task`, `create_task`, `update_task`,
  `report_progress`, `create_epic`, `close_task`.
- **Effort heartbeats** (0 tokens — plain HTTP, no model call):
  - every prompt → **Monkey** (human) time
  - every file edit (`Edit`/`Write`/`MultiEdit`) → **Agent** time
- **Slash commands** (coming): `/heroboard:tasks`, `/heroboard:task <KEY>`, `/heroboard:status`, `/heroboard:ship`.

## Install
```
/plugin marketplace add azamat88b/heroboard-plugin
/plugin install heroboard@heroboard
```

## Set your API key (once)
The plugin reads `HEROBOARD_API_KEY` from your environment. Get a key in Heroboard →
**Settings → MCP → “+ New key”**, then add to your shell profile (e.g. `~/.zshrc`):
```sh
export HEROBOARD_API_KEY="hb_live_…"
```
Restart Claude Code so the MCP server and hooks pick it up. (`/heroboard:login` will automate
this — see HB-233.)

## Migrating from manual hooks
If you set up the heartbeat hooks by hand in `~/.claude/settings.json`, remove them after
installing the plugin so heartbeats don't fire twice.

## Notes
- Heartbeats are fire-and-forget (3s timeout, backgrounded) — they never block or fail a prompt.
- No key set → heartbeats silently no-op; nothing breaks.
