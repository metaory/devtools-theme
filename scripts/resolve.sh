#!/bin/bash
set -euo pipefail

readonly dash='https://chromiumdash.appspot.com/fetch_releases'

spec="${REF:-${CHANNEL:-stable}}"
spec="${spec//$'\n'/}"
ref=$spec
chrome=

[[ $spec == stable || $spec == beta || $spec == canary ]] && {
  read -r build chrome <<<"$(
    curl -fsSL -A devtools-theme \
      "$dash?channel=$spec&platform=Linux&num=1" |
      jq -r '.[0] | "\(.version|split(".")|.[2]) \(.version)"'
  )"
  test -n "$build"
  ref="chromium/$build"
}

printf 'ref=%s\nchrome=%s\n' "$ref" "$chrome"

[[ -z ${GITHUB_OUTPUT-} ]] || printf 'ref=%s\nchrome=%s\n' \
  "$ref" "$chrome" >>"$GITHUB_OUTPUT"
