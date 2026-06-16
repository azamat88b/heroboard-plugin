# Heroboard — Claude Code plugin

Connects your Claude Code session to [Heroboard](https://v2.heroboard.app): task tools over
MCP, effort heartbeats that turn your terminal time into XP, and `/heroboard` commands.

## What you get
- **MCP task tools** — `list_projects`, `list_tasks`, `get_task`, `create_task`, `update_task`,
  `report_progress`, `create_epic`, `close_task`.
- **Effort heartbeats** (0 tokens — plain HTTP, no model call):
  - every prompt → **Monkey** (human) time
  - every agent tool use (edits, `Bash`, search, MCP calls…) → **Agent** time
- **Slash commands**: `/heroboard:login`, `/heroboard:tasks`, `/heroboard:task <KEY>`, `/heroboard:status`, `/heroboard:ship`.

## Install
```
/plugin marketplace add azamat88b/heroboard-plugin
/plugin install heroboard@heroboard
```
On enable, Claude Code **prompts once for your Heroboard API key** and stores it securely in your
system keychain — no `export`, no env var, no config file. Get a key in Heroboard →
**Settings → MCP → “+ New key”**. (Requires Claude Code 2.1.143+.)

The same stored key powers both the MCP server and the effort hooks. It works the same on
macOS / Linux / Windows and in GUI editors (VSCode, JetBrains) — anywhere Claude Code runs.

To change the key later, update the plugin's config via `/plugin` (or disable + re-enable).

## Migrating from manual setup
If you previously added a `~/.claude/settings.json` heartbeat hook or `export HEROBOARD_API_KEY`,
remove them after installing — the plugin replaces both (and reads the key from the keychain).

## Notes
- Heartbeats are fire-and-forget (3s timeout, backgrounded) — never block or fail a prompt.
- No key set → heartbeats silently no-op; nothing breaks.
- Continuous presence ticker is **on by default** — toggle it via the plugin's config (`/plugin`). It keeps effort accruing every ~60s while a session is open, even when you're watching a long agent run and not typing.
