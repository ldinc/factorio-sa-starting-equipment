#!/usr/bin/env python3
"""Turns FactorioTest results into a GitHub Actions job summary and error annotations.

usage: test_summary.py <results.json> <output.log> <mod_dir> <exit_code>

- results.json: written by factorio-test-cli (--output-file)
- output.log:   full console output of the test run (shown when results.json is missing)
- mod_dir:      mod folder in the repo, e.g. "src" (maps __mod_name__/x.lua to src/x.lua)
- exit_code:    exit code of the test run

Writes Markdown to $GITHUB_STEP_SUMMARY (stdout if unset) and prints ::error annotations.
Always exits 0; failing the job is left to the workflow.
"""
import json
import os
import re
import sys
from collections import OrderedDict

ICON = {"passed": "✅", "failed": "❌", "error": "💥", "skipped": "⏭️", "todo": "📝"}
ANSI = re.compile(r"\x1b\[[0-9;]*m")
LUA_LOCATION = re.compile(r"__([\w\-]+)__/([^\s:]+\.lua):(\d+)")


def read_text(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return ANSI.sub("", f.read())
    except OSError:
        return ""


def mod_info(mod_dir):
    try:
        with open(os.path.join(mod_dir, "info.json"), encoding="utf-8-sig") as f:
            info = json.load(f)
        return info.get("name", "?"), info.get("version", "?")
    except (OSError, ValueError):
        return "?", "?"


def repo_location(errors, mod_name, mod_dir):
    """Where the error was raised, as a repo path: the first location inside this mod's files.
    For assertion failures that is the assert line in the test, for runtime errors the failing mod line."""
    for err in errors:
        for m in LUA_LOCATION.finditer(err):
            if m.group(1) == mod_name:
                return f"{mod_dir}/{m.group(2)}", int(m.group(3))
    return None, None


def first_line(text):
    for line in text.splitlines():
        line = LUA_LOCATION.sub("", line).lstrip(": ").strip()
        if line:
            return line
    return "test failed"


def escape_annotation(text):
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(text):
    return escape_annotation(text).replace(":", "%3A").replace(",", "%2C")


def md_escape(text):
    return text.replace("|", "\\|").replace("<", "&lt;").replace(">", "&gt;")


def fmt_ms(ms):
    if ms is None:
        return ""
    if ms < 1:
        return "<1 ms"
    return f"{ms:.0f} ms" if ms < 1000 else f"{ms / 1000:.1f} s"


def blob_url(path, line):
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    repo = os.environ.get("GITHUB_REPOSITORY")
    sha = os.environ.get("GITHUB_SHA")
    if not (repo and sha and path):
        return None
    return f"{server}/{repo}/blob/{sha}/{path}#L{line}"


def main():
    if len(sys.argv) != 5:
        print(__doc__, file=sys.stderr)
        return 0

    results_path, log_path, mod_dir, exit_code = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4] or 1)
    mod_name, mod_version = mod_info(mod_dir)
    factorio = os.environ.get("FACTORIO_VERSION", "?")
    out = []

    try:
        with open(results_path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        data = None

    # ---- run did not produce results: setup / load error
    if not data or not data.get("summary"):
        log = read_text(log_path).strip().splitlines()
        out.append(f"## 💥 Tests did not run — `{mod_name}` {mod_version} on Factorio {factorio}")
        out.append("")
        out.append(f"The test run exited with code **{exit_code}** before producing results "
                   "(image build, mod loading or Lua error while loading tests).")
        out.append("")
        out.append("<details open><summary>Last 60 lines of output</summary>\n")
        out.append("```")
        out.extend(log[-60:] or ["(no output captured)"])
        out.append("```")
        out.append("</details>")
        print(f"::error title=Factorio tests did not run::exit code {exit_code}, see the job summary")
        write_summary(out)
        return 0

    s = data["summary"]
    tests = data.get("tests", [])
    bad = [t for t in tests if t.get("result") in ("failed", "error")]
    total_ms = sum(t.get("durationMs") or 0 for t in tests)
    ok = s.get("status") == "passed" and not bad and exit_code == 0

    # ---- headline + counts
    if ok:
        out.append(f"## ✅ {s.get('passed', 0)} tests passed — `{mod_name}` {mod_version} on Factorio {factorio}")
    else:
        n = len(bad) or s.get("failed", 0)
        out.append(f"## ❌ {n} of {s.get('ran', len(tests))} tests failed — `{mod_name}` {mod_version} on Factorio {factorio}")
    out.append("")
    out.append("| Passed | Failed | Errors | Skipped | Todo | Duration |")
    out.append("|---:|---:|---:|---:|---:|---:|")
    out.append(f"| {s.get('passed', 0)} | {s.get('failed', 0)} | {s.get('describeBlockErrors', 0)} "
               f"| {s.get('skipped', 0)} | {s.get('todo', 0)} | {fmt_ms(total_ms)} |")
    out.append("")
    if s.get("skipped"):
        out.append("> Skipped tests are tagged `needs-player` (headless Factorio has no players). "
                   "Run them locally with `run-tests.ps1 -Graphics`.")
        out.append("")

    # ---- failures, with source links and annotations
    if bad:
        out.append("### Failures")
        out.append("")
        for t in bad:
            errors = [ANSI.sub("", e) for e in t.get("errors") or []]
            text = "\n".join(errors).strip() or "(no error message)"
            path, line = repo_location(errors, mod_name, mod_dir)
            url = blob_url(path, line)
            where = f" — [{path}:{line}]({url})" if url else (f" — `{path}:{line}`" if path else "")
            out.append(f"#### {ICON.get(t['result'], '❌')} {md_escape(t['path'])}{where}")
            out.append("")
            out.append("```")
            out.extend(text.splitlines()[:25])
            out.append("```")
            out.append("")

            title = escape_property(t["path"])
            message = escape_annotation(first_line(text))
            if path:
                print(f"::error file={path},line={line},title={title}::{message}")
            else:
                print(f"::error title={title}::{message}")

    # ---- all tests, grouped by test file
    groups = OrderedDict()
    for t in tests:
        file, _, rest = t["path"].partition(" > ")
        groups.setdefault(file, []).append((rest or file, t))

    out.append("<details><summary>All tests</summary>\n")
    for file, items in groups.items():
        counts = {}
        for _, t in items:
            counts[t["result"]] = counts.get(t["result"], 0) + 1
        badge = " · ".join(f"{ICON.get(k, k)} {v}" for k, v in counts.items())
        out.append(f"**{md_escape(file)}** — {badge}\n")
        out.append("| | Test | Time |")
        out.append("|---|---|---:|")
        for name, t in items:
            out.append(f"| {ICON.get(t['result'], t['result'])} | {md_escape(name)} | {fmt_ms(t.get('durationMs'))} |")
        out.append("")
    out.append("</details>")

    write_summary(out)
    return 0


def write_summary(lines):
    text = "\n".join(lines) + "\n"
    target = os.environ.get("GITHUB_STEP_SUMMARY")
    if target:
        with open(target, "a", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    sys.exit(main())
