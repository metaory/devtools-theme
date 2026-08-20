#!/bin/bash
set -euo pipefail

if [[ ! ${1-} ]]; then
  cat <<EOF
usage: screenshot.sh front_end
  writes .github/assets/screenshot-{0..n}.png
  HUE               default preset → screenshot-0
  HUES SPREAD SAT   required
  RADIUS            32

HUE=270 HUES='80 180 250 280 320 10' SPREAD=20 SAT=50 screenshot.sh front_end
EOF
  exit 1
fi

die() { printf '%s\n' "$*" >&2 && exit 1; }
need() { command -v "$1" >/dev/null || die "missing command: $1"; }
stop() {
  kill "$1" 2>/dev/null || true
  wait "$1" 2>/dev/null || true
}

browser=${BROWSER:-chromium}
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

source "$root/scripts/overlay.sh" env

: "${HUE:?}" "${HUES:?}" "${SPREAD:?}" "${SAT:?}"

front=$(realpath "$1")
out="$root/.github/assets"
tmp=$(mktemp -d)
shm=()
pid=

[[ ${GITHUB_ACTIONS-} ]] && shm=(--disable-dev-shm-usage)

mkdir -p "$out"

for c in "$browser" convert identify curl jq node awk; do need "$c"; done

test -f "$front/devtools_app.html" || die "missing $front/devtools_app.html"

function cleanup {
  status=$?
  ((status)) && {
    port=$(head -n1 "$tmp/profile/DevToolsActivePort" 2>/dev/null || true)
    [[ $port ]] && curl -fsS "http://127.0.0.1:$port/json/list" >&2 || true
    cat "$tmp"/chrome.log "$tmp"/capture.log >&2 2>/dev/null || true
  }
  [[ ${pid-} ]] && stop "$pid"
  rm -rf "$tmp" || true
}

trap cleanup EXIT

cp "$root/scripts/screenshot.html" "$tmp/index.html"

flags=(
  --allow-file-access-from-files
  --disable-background-networking
  --disable-extensions
  --disable-gpu
  --headless=new
  --hide-scrollbars
  --no-first-run
  --no-sandbox
  --remote-allow-origins=*
  --remote-debugging-port=0
  "${shm[@]}"
)

function page_ws {
  curl -fsS "http://127.0.0.1:$1/json/list" |
    jq -r --arg p "$2" \
      '.[] | select(.type=="page" and (.url | contains($p))) | .webSocketDebuggerUrl' ||
    true
}

function chrome_ws {
  local dir=$1 pat=$2 tries=$3 check=${4-} i port ws
  for ((i = 0; i < tries; i++)); do
    [[ $check ]] && ! kill -0 "$check" 2>/dev/null && return 1
    [[ -s $dir/DevToolsActivePort ]] || {
      sleep 0.25
      continue
    }
    port=$(head -n1 "$dir/DevToolsActivePort")
    ws=$(page_ws "$port" "$pat")
    [[ $ws == ws://* ]] && {
      printf '%s\n' "$ws"
      return
    }
    sleep 0.25
  done
  return 1
}

"$browser" "${flags[@]}" \
  --user-data-dir="$tmp/profile" \
  "file://$tmp/index.html" >"$tmp/chrome.log" 2>&1 &
pid=$!

ws=$(chrome_ws "$tmp/profile" index.html 240 "$pid") ||
  die "‼ no page websocket"

function write_app {
  cat >"$tmp/devtools.html" <<EOF
<!doctype html>
<html lang=en>
<meta charset=utf-8>
<title>DevTools</title>
<base href="file://$front/">
<script type=module src="entrypoints/devtools_app/devtools_app.js"></script>
<link href="application_tokens.css" rel=stylesheet>
<link href="design_system_tokens.css" rel=stylesheet>
<style>:root{--hue:${1};--spread:${SPREAD};--sat-in:${SAT}}</style>
<body class=undocked id=-blink-dev-tools style="--user-color-source:baseline-default">
EOF
}

app="file://$tmp/devtools.html?ws=${ws#ws://}"

printf 'port %s\nfrontend %s\n%s\n' "$(head -n1 "$tmp/profile/DevToolsActivePort")" "$front" "$app"

function capture {
  local name=$1 cap browser_pid cap_ws bytes t
  shift
  for t in 1 2 3; do
    cap="$tmp/cap-$name"
    rm -rf "$cap"
    mkdir -p "$cap"
    "$browser" "${flags[@]}" \
      --force-device-scale-factor=1 \
      --run-all-compositor-stages-before-draw \
      --user-data-dir="$cap" \
      --window-size=1200,800 \
      "$@" "$app" >"$cap.log" 2>&1 &
    browser_pid=$!

    cap_ws=$(chrome_ws "$cap" devtools.html 100 "$browser_pid") || cap_ws=

    rm -f "$out/screenshot-$name.png"

    [[ $cap_ws == ws://* ]] &&
      node "$root/scripts/screenshot.mjs" "$cap_ws" "$out/screenshot-$name.png" \
        >"$tmp/capture.log" 2>&1 &&
      bytes=$(stat -c%s "$out/screenshot-$name.png" 2>/dev/null || echo 0) &&
      ((bytes > 10000)) && {
      echo "$bytes bytes $name"
      stop "$browser_pid"
      return
    }

    echo "‼ retry $name ($t)" >&2
    cat "$tmp/capture.log" "$cap.log" >&2 || true
    stop "$browser_pid"
  done

  die "⁈‼ failed screenshot: $name"
}

function round {
  local img=$1 r=${RADIUS:-32}
  local w h
  read -r w h < <(identify -format '%w %h\n' "$img")
  convert "$img" \
    \( -size "${w}x${h}" xc:none \
    -draw "roundrectangle 0,0 $((w - 1)),$((h - 1)) $r,$r" \) \
    -alpha set -compose DstIn -composite "$img"
}

function pair {
  local n=$1
  local light=$out/screenshot-$n-light.png
  local dark=$out/screenshot-$n-dark.png
  local w h dx dy
  round "$light"
  round "$dark"
  read -r w h < <(identify -format '%w %h\n' "$light")
  dx=$((w * 10 / 100))
  dy=$((h * 10 / 100))
  convert -size "$((w + dx))x$((h + dy))" xc:none \
    "$light" -geometry "+0+${dy}" -composite \
    "$dark" -geometry "+${dx}+0" -composite \
    "$out/screenshot-$n.png"
  rm -f "$light" "$dark"
}

function gallery {
  local n=${#hues[@]} i repo=${GITHUB_REPOSITORY:-metaory/devtools-theme}
  local src="https://raw.githubusercontent.com/$repo/screenshots"
  printf '  <!-- screenshots -->\n'
  for ((i = 1; i < n; i++)); do
    ((i % 2)) && printf '  '
    printf '<img src="%s/screenshot-%s.png" width="40%%" />' "$src" "$i"
    ((i % 2 && i < n - 1)) && printf '&nbsp;&nbsp;'
    ((i % 2 == 0 && i < n - 1)) && printf '\n  <br>\n  <br>\n'
    ((i == n - 1)) && printf '\n'
  done
  printf '  <!-- /screenshots -->\n'
}

function patch_readme {
  local readme=$root/README.md
  grep -q '<!-- screenshots -->' "$readme" || die "missing README screenshot start marker"
  grep -q '<!-- /screenshots -->' "$readme" || die "missing README screenshot end marker"
  gallery >"$tmp/gallery"
  awk '
    /<!-- screenshots -->/ {
      while ((getline line < g) > 0) print line
      close(g)
      skip=1
      next
    }
    /<!-- \/screenshots -->/ { skip=0; next }
    !skip
  ' g="$tmp/gallery" "$readme" >"$tmp/README.md"
  mv "$tmp/README.md" "$readme"
}

rm -f "$out"/screenshot-*.png

read -ra hues <<<"$HUE $HUES"

for i in "${!hues[@]}"; do
  write_app "${hues[i]}"
  capture "$i-light" --blink-settings=preferredColorScheme=1
  capture "$i-dark" --blink-settings=preferredColorScheme=0
  pair "$i"
done

patch_readme

ls -lh "$out"/screenshot-*.png
