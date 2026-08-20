#!/bin/bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d)
home="$tmp/home"
tar="$tmp/frontend.tar"
archive="$tmp/archive"
front="$home/.local/share/chromium/front_end"

trap 'rm -rf "$tmp"' EXIT

fail() { printf 'test failed: %s\n' "$1" >&2 && exit 1; }

function count {
  local text=$1 needle=$2 n=0
  while [[ $text == *"$needle"* ]]; do
    text=${text#*"$needle"}
    ((++n))
  done
  printf '%s\n' "$n"
}

mkdir -p "$archive/front_end/ui/legacy"
printf ':root { --upstream: 1; }\n' >"$archive/front_end/design_system_tokens.css"
printf 'const source = true;\n//# sourceURL=inspectorCommon.css.js\n' \
  >"$archive/front_end/ui/legacy/inspectorCommon.css.js"
printf 'fixture license\n' >"$archive/LICENSE"

tar -C "$archive" -cf "$tar" front_end LICENSE

# First call extracts. The second verifies reapplying is idempotent.
HOME="$home" "$root/apply" "$tar" >/dev/null
HOME="$home" "$root/apply" "$tar" >/dev/null

tokens=$(<"$front/design_system_tokens.css")
common=$(<"$front/ui/legacy/inspectorCommon.css.js")

[[ $(count "$tokens" '/* === config.css === */') == 1 ]] || fail '⁈‼ config marker'
[[ $(count "$tokens" '/* === theme.css === */') == 1 ]] || fail '⁈‼ theme marker'
[[ $(count "$common" '/* === inspector.css === */') == 1 ]] || fail '⁈‼ inspector marker'
[[ $common == *'//# sourceURL=inspectorCommon.css.js' ]] || fail '⁈‼ source URL'
[[ $(<"$home/.local/share/chromium/LICENSE") == 'fixture license' ]] || fail '⁈‼ license'

printf 'keep\n' >"$front/keep"
rm "$front/design_system_tokens.css"
mkdir -p "$tmp/invalid/front_end"
tar -C "$tmp/invalid" -cf "$tmp/invalid.tar" front_end

if HOME="$home" "$root/apply" "$tmp/invalid.tar" >/dev/null 2>&1; then
  fail '⁈‼ invalid archive accepted'
fi

[[ $(<"$front/keep") == keep ]] || fail '⁈‼ frontend was replaced after invalid archive'

printf '✔ apply smoke test passed\n'
