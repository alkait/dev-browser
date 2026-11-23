# dev-browser

**Give Claude Code a real browser that stays signed in.**

Ask Claude to check something on a website, reproduce a bug, read a page's console errors, test the browser extension you're building, or do a task on a site you're logged in to. Claude opens its own browser window and does it, so you don't have to copy and paste from the browser.

The browser is separate from the one you use every day, so your normal tabs, history and passwords aren't touched. Sign in to a site there once and you stay signed in.

## What you need

- [Claude Code](https://code.claude.com): in the terminal, or in the **Code** tab of the Claude desktop app
- One of Google Chrome, Brave, Microsoft Edge or Chromium
- [Node.js](https://nodejs.org) 22 or newer
- macOS or Linux

## Install

In Claude Code, run these two commands:

```
/plugin marketplace add alkait/dev-browser
/plugin install dev-browser@dev-browser
```

Then run `/reload-plugins`, or restart Claude Code.

## Try it

Ask Claude:

> open example.com in the dev browser and tell me what's on it

A new browser window opens, and Claude tells you what's on the page.

To use a site where you need to be logged in, ask Claude to open it, then sign in yourself in that window. Claude never types your passwords. You only do this once.

When you're done, ask Claude to close the dev browser. While it's open, other programs on your computer could control it too.

## Uninstall

```
/plugin uninstall dev-browser@dev-browser
/plugin marketplace remove dev-browser
```

## License

MIT
