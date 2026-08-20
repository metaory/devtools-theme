#!/bin/bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

pairs=(
  hue:HUE
  sat-in:SAT
  spread:SPREAD
  hue-error:HUE_ERROR
  hue-blue:HUE_BLUE
  hue-green:HUE_GREEN
  hue-orange:HUE_ORANGE
  hue-yellow:HUE_YELLOW
  hue-cyan:HUE_CYAN
  hue-pink:HUE_PINK
)

parse() {
  [[ -f ${1-} ]] || return 0
  while read -r css val; do
    for p in "${pairs[@]}"; do
      [[ ${p%%:*} == "$css" ]] || continue
      printf '%s %s\n' "${p#*:}" "$val"
    done
  done < <(sed -En 's/^[[:space:]]*--([a-z-]+):[[:space:]]*([0-9]+);.*/\1 \2/p' "$1")
}

fill() {
  while read -r n val; do
    v=${!n-}
    [[ $v =~ ^[0-9]+$ ]] || printf -v "$n" %s "$val"
  done < <(parse "$root/config.css")
}

[[ ${1-} == parse ]] && {
  parse "$2"
  exit
}

[[ ${1-} == inspector.css ]] && {
  printf '\n/* === inspector.css === */\n'
  exec cat "$root/inspector.css"
}

fill
printf '\n/* === config.css === */\n:root {\n'
for p in "${pairs[@]}"; do
  n=${p#*:}
  printf '  --%s: %s;\n' "${p%%:*}" "${!n}"
done
printf '}\n\n/* === theme.css === */\n'
cat "$root/theme.css"
