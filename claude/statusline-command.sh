#!/bin/bash
# Status line: model effort · 5h %left (resets in) · 7d %left (resets in) · dir ·
# git branch · session name.
# Missing parts are skipped.
input=$(cat)

US=$'\x1f'
IFS="$US" read -r model effort dir name five reset5 week reset7 < <(
  echo "$input" | jq -r '
    def left: if . == null then "" else (100 - .) | round | tostring end;
    def until: if . == null or . <= now then "" else (. - now) / 60 | ceil as $m |
      if $m >= 1440 then "\($m / 1440 | floor)d"
      elif $m >= 60 then "\($m / 60 | floor)h"
      else "\($m)m" end end;
    [ .model.display_name // "",
      .effort.level // "",
      .workspace.current_dir // .cwd // "",
      .session_name // "",
      (.rate_limits.five_hour.used_percentage | left),
      (.rate_limits.five_hour.resets_at | until),
      (.rate_limits.seven_day.used_percentage | left),
      (.rate_limits.seven_day.resets_at | until)
    ] | join("\u001f")' 2>/dev/null
)

branch=""
[ -n "$dir" ] && branch=$(git --no-optional-locks -C "$dir" branch --show-current 2>/dev/null)

short_dir="$dir"
case "$dir" in "$HOME"*) short_dir="~${dir#"$HOME"}" ;; esac

parts=()
add() { # add R;G;B TEXT
  [ -n "$2" ] && parts+=("$(printf '\033[38;2;%sm%s\033[0m' "$1" "$2")")
}

label="$model"
[ -n "$effort" ] && label="${label:+$label }$effort"

add "229;200;144" "$label"
[ -n "$five" ] && add "243;139;168" "5h $five%${reset5:+ ($reset5)}"
[ -n "$week" ] && add "148;226;213" "7d $week%${reset7:+ ($reset7)}"
add "166;227;161" "$short_dir"
add "137;180;250" "$branch"
add "203;166;247" "$name"

sep=$'\033[38;2;108;112;134m · \033[0m'
out=""
for p in "${parts[@]}"; do out="${out:+$out$sep}$p"; done
printf '%s\n' "$out"
