# Development notes

## How it works

```
dev-browser start ──launches──▶ Chrome / Brave / Edge / Chromium
                                 (own profile, DevTools port 9222, no automation flags)
                                     ▲
                                     │ Chrome DevTools Protocol
chrome-devtools MCP server ──────────┘ attaches; never launches
        ▲
        │ tool calls
   Claude Code ◀── skill: when and how to use it
```

- `bin/dev-browser`: the launcher (`start`, `restart`, `stop`, `status`, `mcp`; see `--help`). Claude Code adds a plugin's `bin/` to the end of PATH, so the skill calls it by full path (`${CLAUDE_PLUGIN_ROOT}/bin/dev-browser`).
- `.mcp.json`: runs `dev-browser mcp`, which starts `chrome-devtools-mcp@latest --browserUrl http://127.0.0.1:$PORT`.
- `skills/dev-browser/SKILL.md`: instructions for the agent.
- Profiles live in `~/.local/share/dev-browser/profiles/<browser>/<name>`. Settings are in `~/.config/dev-browser/config` (`DEV_BROWSER_BIN`, `DEV_BROWSER_PROFILE`, `DEV_BROWSER_PORT`, `DEV_BROWSER_MCP_ARGS`). Environment variables override the config file, and `--browser`, `--profile` and `--port` override both.
- Extensions load through DevTools (`Extensions.loadUnpacked`, which needs `--enable-unsafe-extension-debugging`), because Chrome 137+ ignores `--load-extension`. Loading the same folder again reloads it.
- `stop` closes the browser with `Browser.close`, so cookies (sign-ins) are flushed to disk. SIGTERM can lose recent ones. It only closes a browser it started.

## Working on it

```
claude --plugin-dir .      # run Claude Code with your working copy
tests/smoke.sh brave       # 14 checks with throwaway profiles on port 9333
claude plugin validate .
```

Bump `version` in `.claude-plugin/plugin.json` and `VERSION` in `bin/dev-browser` for each release, or `/plugin update` won't pick up changes.
