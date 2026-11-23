#!/bin/sh
# Smoke test for bin/dev-browser. Uses throwaway profiles under a temp folder
# and port 9333, so your real dev-browser profile and port 9222 are untouched.
#
#   tests/smoke.sh [BROWSER]     BROWSER: chrome, brave, brave-origin, ... (default: auto)
#
# Needs: curl, node 22+, network access (example.com, npm registry).

here=$(cd "$(dirname "$0")" && pwd)
DB="$here/../bin/dev-browser"
PORT=9333
work=$(mktemp -d "${TMPDIR:-/tmp}/dev-browser-smoke.XXXXXX")
export XDG_DATA_HOME="$work/data" XDG_CONFIG_HOME="$work/config"
B=${1:+--browser $1}
pass=0 fail=0

ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; }
check() { # check NAME EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected $2, got $3)"; fi
}
eval_in() { node "$here/cdp-eval.mjs" "$PORT" "$1" "$2" 2>/dev/null; }
cleanup() { "$DB" stop --port $PORT >/dev/null 2>&1; rm -rf "$work"; }
trap cleanup EXIT INT TERM

echo "dev-browser smoke test (temp: $work)"

# shellcheck disable=SC2086
"$DB" start $B --profile p1 --port $PORT https://example.com >/dev/null &&
  ok "start" || { bad "start"; exit 1; }
sleep 2
check "page opened" '"Example Domain"' "$(eval_in example.com 'document.title')"
check "navigator.webdriver is false" 'false' "$(eval_in example.com 'navigator.webdriver')"
"$DB" status --port $PORT >/dev/null && ok "status (running)" || bad "status (running)"

"$DB" start --port $PORT https://example.org >/dev/null && ok "start again is a no-op" || bad "start again"
sleep 2
check "start again opens URL" '"Example Domain"' "$(eval_in example.org 'document.title')"

"$DB" start --port $PORT --ext "$here/fixture-extension" >/dev/null &&
  ok "load extension into running browser" || bad "load extension into running browser"
curl -sf -X PUT "http://127.0.0.1:$PORT/json/new?https://example.net" >/dev/null; sleep 2
check "extension content script ran" '"loaded"' \
  "$(eval_in example.net 'document.documentElement.dataset.devBrowserFixture ?? null')"

eval_in example.com 'document.cookie = "smoke=1; max-age=3600; secure"' >/dev/null
"$DB" stop --port $PORT >/dev/null && ok "stop" || bad "stop"
curl -sf "http://127.0.0.1:$PORT/json/version" >/dev/null && bad "port closed after stop" || ok "port closed after stop"

# shellcheck disable=SC2086
"$DB" start $B --profile p1 --port $PORT https://example.com >/dev/null; sleep 2
check "cookie survived restart" '"smoke=1"' "$(eval_in example.com 'document.cookie')"

# shellcheck disable=SC2086
"$DB" start $B --profile p1 --port 9334 >/dev/null 2>&1 &&
  { bad "refuse profile already in use"; "$DB" stop --port 9334 >/dev/null; } ||
  ok "refuse profile already in use"

if DEV_BROWSER_PORT=$PORT node "$here/mcp-smoke.mjs" "$DB" >"$work/mcp.log" 2>&1; then
  ok "MCP server lists pages"
else
  bad "MCP server lists pages (see output below)"; cat "$work/mcp.log"
fi

"$DB" stop --port $PORT >/dev/null
"$DB" stop --port $PORT | grep -q "Not running" && ok "stop when not running" || bad "stop when not running"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
