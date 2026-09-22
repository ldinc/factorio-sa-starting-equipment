#!/usr/bin/env python3
"""GitHub Actions summary + annotations for luacheck and the Factorio API type check.

usage: lint_summary.py <luacheck.txt> <luacheck_exit> <typecheck.json> <typecheck.log> <typecheck_exit>

- luacheck.txt:   output of `luacheck --formatter plain --codes`
- typecheck.json: problems written by docker/typecheck.sh (OUT=...)
- typecheck.log:  console output of the typecheck run (shown if it could not run)
Always exits 0; failing the job is left to the workflow.
"""
import json
import os
import re
import sys

LUACHECK_LINE = re.compile(r"^(?P<file>[^:]+\.lua):(?P<line>\d+):(?P<col>\d+): \((?P<code>[EW]\d+)\) (?P<msg>.*)$")
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return ANSI.sub("", f.read())
    except OSError:
        return ""


def as_int(text, default=1):
    try:
        return int(text)
    except (TypeError, ValueError):
        return default


def esc_data(text):
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def esc_prop(text):
    return esc_data(text).replace(":", "%3A").replace(",", "%2C")


def md(text):
    return text.replace("|", "\\|").replace("<", "&lt;").replace(">", "&gt;")


def link(path, line):
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    repo, sha = os.environ.get("GITHUB_REPOSITORY"), os.environ.get("GITHUB_SHA")
    label = f"{path}:{line}"
    if repo and sha:
        return f"[{md(label)}]({server}/{repo}/blob/{sha}/{path}#L{line})"
    return f"`{label}`"


def annotate(level, file, line, col, title, message):
    print(f"::{level} file={file},line={line},col={col},title={esc_prop(title)}::{esc_data(message)}")


def table(rows, limit=100):
    out = ["| Location | Code | Message |", "|---|---|---|"]
    for r in rows[:limit]:
        out.append(f"| {link(r['file'], r['line'])} | `{r['code']}` | {md(r['message'])} |")
    if len(rows) > limit:
        out.append(f"| … | | {len(rows) - limit} more, see the annotations / artifact |")
    return out


def main():
    if len(sys.argv) != 6:
        print(__doc__, file=sys.stderr)
        return 0
    lc_file, lc_exit, tc_file, tc_log, tc_exit = sys.argv[1:]
    lc_exit, tc_exit = as_int(lc_exit), as_int(tc_exit)
    factorio = os.environ.get("FACTORIO_VERSION", "?")

    # ---- luacheck
    lc_rows = []
    for raw in read(lc_file).splitlines():
        m = LUACHECK_LINE.match(raw.strip())
        if m:
            row = m.groupdict()
            lc_rows.append(row)
            level = "error" if row["code"].startswith("E") else "warning"
            annotate(level, row["file"], row["line"], row["col"], f"luacheck {row['code']}", row["msg"])
    for r in lc_rows:
        r["message"] = r.pop("msg")
    lc_broken = lc_exit >= 3 or (lc_exit != 0 and not lc_rows)

    # ---- typecheck
    try:
        with open(tc_file, encoding="utf-8") as f:
            tc_rows = json.load(f)
    except (OSError, ValueError):
        tc_rows = None
    tc_broken = tc_rows is None and tc_exit != 0
    for r in tc_rows or []:
        level = "error" if r.get("severity") == "error" else "warning"
        annotate(level, r["file"], r["line"], r["col"], f"Factorio API: {r['code']}", r["message"])

    # ---- headline
    parts = []
    if lc_rows:
        parts.append(f"{len(lc_rows)} luacheck issue(s)")
    if tc_rows:
        parts.append(f"{len(tc_rows)} Factorio API problem(s)")
    if lc_broken:
        parts.append("luacheck did not run")
    if tc_broken:
        parts.append("type check did not run")

    out = []
    if not parts:
        out.append(f"## ✅ Lint clean — luacheck and Factorio {factorio} API type check")
    else:
        out.append(f"## ⚠️ Lint: {' · '.join(parts)}")
    out.append("")

    out.append(f"### luacheck — {'✅ no issues' if not lc_rows and not lc_broken else ('💥 did not run' if lc_broken else f'{len(lc_rows)} issue(s)')}")
    out.append("")
    if lc_rows:
        out.extend(table(lc_rows))
        out.append("")
    elif lc_broken:
        out.append(f"luacheck exited with code {lc_exit}:\n\n```\n{read(lc_file).strip()[-3000:]}\n```\n")

    title = f"Factorio {factorio} API type check (Lua Language Server)"
    if tc_broken:
        out.append(f"### {title} — 💥 did not run")
        out.append("")
        out.append(f"Exit code {tc_exit}. Last lines of output:\n\n```\n" + "\n".join(read(tc_log).strip().splitlines()[-40:]) + "\n```\n")
    elif tc_rows:
        out.append(f"### {title} — {len(tc_rows)} problem(s)")
        out.append("")
        out.extend(table(tc_rows))
        out.append("")
        out.append("> Usually a typo in a Factorio API name (`LuaPlayer`, `defines`, event fields ...). "
                   "Intentional cases can be silenced with `---@diagnostic disable-next-line: <code>`.")
    else:
        out.append(f"### {title} — ✅ no problems")
    out.append("")

    text = "\n".join(out) + "\n"
    target = os.environ.get("GITHUB_STEP_SUMMARY")
    if target:
        with open(target, "a", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
