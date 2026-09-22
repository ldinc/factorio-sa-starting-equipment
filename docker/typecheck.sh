#!/bin/sh
# usage: typecheck [dir]   dir is relative to the repo mounted at /data (default: src)
# env:   OUT=/results/typecheck.json  also write the problems as JSON (for CI)
#        CHECKLEVEL=Warning           minimum severity: Error | Warning | Information | Hint
set -u
DIR="${1:-src}"
DATA="${DATA:-/data}"
LIB="${LIB:-/opt/factorio-types/factorio}"
LUALS="${LUALS:-/opt/luals/bin/lua-language-server}"
REPORT="${REPORT:-/usr/local/lib/typecheck-report.js}"
TMP="$(mktemp -d)"

# Repo-level extra definitions (FactorioTest + luassert globals for tests)
EXTRA=""
[ -d "$DATA/.luals" ] && EXTRA=", \"$DATA/.luals\""

cat > "$TMP/luarc.json" <<JSON
{
  "runtime.version": "Lua 5.2",
  "runtime.path": ["?.lua"],
  "runtime.builtin": { "io": "disable", "os": "disable", "coroutine": "disable" },
  "runtime.plugin": "$LIB/plugin.lua",
  "workspace.library": ["$LIB/library"$EXTRA],
  "workspace.checkThirdParty": false,
  "diagnostics.disable": ["lowercase-global"]
}
JSON

if [ ! -d "$DATA/$DIR" ]; then
  echo "typecheck: $DATA/$DIR not found" >&2
  exit 3
fi

echo "Type-checking $DIR against the Factorio API ($(cat "$LIB/config.json" | sed -n 's/.*"factorioVersion":"\([^"]*\)".*/\1/p'))"
"$LUALS" --check="$DATA/$DIR" --configpath="$TMP/luarc.json" --logpath="$TMP/log" \
  --checklevel="${CHECKLEVEL:-Warning}" --check_format=json >/dev/null 2>&1

node "$REPORT" "$TMP/log/check.json" "$DATA" "${OUT:-}"
status=$?
rm -rf "$TMP"
exit $status
