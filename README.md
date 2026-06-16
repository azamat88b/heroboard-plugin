# Heroboard — Claude Code plugin marketplace

**Source of truth.** This directory (`packages/claude-plugin` in the monorepo) is the canonical
source for the Heroboard Claude Code plugin. It is mirrored to the public marketplace repo
**[azamat88b/heroboard-plugin](https://github.com/azamat88b/heroboard-plugin)** that users install from.

## Install (for users)
```
/plugin marketplace add azamat88b/heroboard-plugin
/plugin install heroboard@heroboard
```
Claude Code then prompts for your Heroboard API key (Heroboard → Settings → MCP → “+ New key”) and stores it in your system keychain — no `export`, no env var. The one key powers both the MCP server and the effort heartbeats. Run `/heroboard:login` to verify. (For effort tracking inside the Claude desktop/web app, run the plugin in a terminal once — see `plugins/heroboard/README.md`.)

The plugin bundles the Heroboard MCP tools, effort heartbeats (Monkey/Agent time, 0 tokens),
and `/heroboard` slash commands. See `plugins/heroboard/README.md`.

## Publish a change (HB-238)
1. Edit files here in the monorepo.
2. Bump `plugins/heroboard/.claude-plugin/plugin.json` `version` so installers get the update.
3. Run `./publish.sh` — it mirrors this directory to the marketplace repo and pushes.

Never hand-edit the public repo directly; it drifts. The monorepo is authoritative.
