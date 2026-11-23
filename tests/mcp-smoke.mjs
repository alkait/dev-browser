// Usage: node mcp-smoke.mjs PATH-TO-dev-browser
// Starts `dev-browser mcp`, lists its tools, and calls list_pages against the running browser.
import { spawn } from "node:child_process";
const child = spawn(process.argv[2], ["mcp"], { stdio: ["pipe", "pipe", "inherit"] });
let buf = "", nextId = 1;
const waiting = new Map();
child.stdout.on("data", (d) => {
  buf += d;
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i); buf = buf.slice(i + 1);
    if (!line.trim()) continue;
    const msg = JSON.parse(line);
    if (waiting.has(msg.id)) { waiting.get(msg.id)(msg); waiting.delete(msg.id); }
  }
});
const rpc = (method, params = {}) => new Promise((resolve) => {
  const id = nextId++; waiting.set(id, resolve);
  child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
});
setTimeout(() => { console.error("timeout"); process.exit(1); }, 120000);
const init = await rpc("initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "smoke", version: "0" } });
console.log("server:", init.result.serverInfo.name, init.result.serverInfo.version);
child.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n");
const tools = await rpc("tools/list");
console.log("tools:", tools.result.tools.length, tools.result.tools.map((t) => t.name).slice(0, 8).join(", "), "...");
const pages = await rpc("tools/call", { name: "list_pages", arguments: {} });
console.log("list_pages:", JSON.stringify(pages.result ?? pages.error).slice(0, 500));
child.kill(); process.exit(pages.result && !pages.result.isError ? 0 : 1);
