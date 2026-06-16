---
description: Connect this session to Heroboard (set & verify your API key)
---
Onboard me to Heroboard. Do this step by step:

1. Check whether `HEROBOARD_API_KEY` is set in the environment (run `printenv HEROBOARD_API_KEY` — only report whether it's present, never print the value).
2. **If it's missing**, tell me to:
   - open Heroboard → **Settings → MCP → “+ New key”**, copy the key (shown once),
   - add `export HEROBOARD_API_KEY="hb_live_…"` to my shell profile (`~/.zshrc` or `~/.bashrc`),
   - restart Claude Code so the MCP server and hooks pick it up.
   Do NOT ask me to paste the key into the chat.
3. **If it's set**, verify the connection by calling the heroboard MCP tool `list_projects`. If it returns projects, confirm "✅ connected" and list them. If it 401s, the key is invalid/revoked — point me back to step 2.
4. Briefly note that effort heartbeats (Monkey on prompts, Agent on edits) are now active and cost no tokens.
