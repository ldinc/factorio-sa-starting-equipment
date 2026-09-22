// Prints LuaLS --check results as "file:line:col: severity [code] message" and exits 1 if there are any.
// usage: node typecheck-report.js <check.json> <repo root> [out.json]
const fs = require("fs")
const [checkFile, root, out] = process.argv.slice(2)
const SEVERITY = { 1: "error", 2: "warning", 3: "info", 4: "hint" }

let raw = []
try {
  raw = JSON.parse(fs.readFileSync(checkFile, "utf8"))
} catch (e) {
  console.error(`typecheck: no results from lua-language-server (${e.message})`)
  process.exit(3)
}

const problems = []
for (const [uri, diags] of Array.isArray(raw) ? [] : Object.entries(raw)) {
  let file = decodeURIComponent(uri.replace(/^file:\/\//, ""))
  const prefix = root.replace(/\/$/, "") + "/"
  if (file.startsWith(prefix)) file = file.slice(prefix.length)
  for (const d of diags) {
    problems.push({
      file,
      line: d.range.start.line + 1,
      col: d.range.start.character + 1,
      severity: SEVERITY[d.severity] || "warning",
      code: d.code,
      message: String(d.message).split("\n")[0],
    })
  }
}
problems.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line || a.col - b.col)

for (const p of problems) console.log(`${p.file}:${p.line}:${p.col}: ${p.severity} [${p.code}] ${p.message}`)
const files = new Set(problems.map((p) => p.file)).size
console.log(problems.length ? `\n${problems.length} problem(s) in ${files} file(s)` : "No problems found")

if (out) fs.writeFileSync(out, JSON.stringify(problems, null, 2))
process.exit(problems.length ? 1 : 0)
