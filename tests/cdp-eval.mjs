// Usage: node cdp-eval.mjs PORT URL-SUBSTRING EXPRESSION
// Evaluates EXPRESSION in the first page whose URL contains URL-SUBSTRING and prints the result.
const [port, match, expr] = process.argv.slice(2);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const page = targets.find((t) => t.type === "page" && t.url.includes(match));
if (!page) { console.error(`no page matching ${match}: ${targets.map((t) => t.url).join(", ")}`); process.exit(1); }
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
ws.send(JSON.stringify({ id: 1, method: "Runtime.evaluate", params: { expression: expr, returnByValue: true, awaitPromise: true } }));
const msg = await new Promise((r) => { ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id === 1) r(m); }; });
ws.close();
if (msg.result?.exceptionDetails) { console.error(JSON.stringify(msg.result.exceptionDetails)); process.exit(1); }
console.log(JSON.stringify(msg.result?.result?.value));
