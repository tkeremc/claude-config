#!/usr/bin/env bash
# Status line:
#   model (effort) · folder (branch *dirty) · context N% · 5h N% · 7d N% · +added −removed · duration · $cost
# Segments whose data is missing are left out.
input=$(cat)

IFS=$'\x1f' read -r model effort dir ctx five week added removed dur_ms cost < <(
  jq -r '[
    .model.display_name // "?",
    .effort.level // "",
    .workspace.current_dir // .cwd // "",
    ((.context_window.used_percentage // 0) | floor),
    (.rate_limits.five_hour.used_percentage | if . == null then "" else floor end),
    (.rate_limits.seven_day.used_percentage | if . == null then "" else floor end),
    .cost.total_lines_added // 0,
    .cost.total_lines_removed // 0,
    ((.cost.total_duration_ms // 0) | floor),
    .cost.total_cost_usd // 0
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

# Snapshot the usage limits for the usage-limit skill (main session reads it on demand).
if jq -e '.rate_limits.five_hour or .rate_limits.seven_day' <<<"$input" >/dev/null 2>&1; then
  mkdir -p "$HOME/.claude/cache"
  tmp=$(mktemp "$HOME/.claude/cache/usage-limits.XXXXXX") &&
    jq -c '{five_hour: .rate_limits.five_hour, seven_day: .rate_limits.seven_day, written_at: now | floor}' <<<"$input" >"$tmp" &&
    mv -f "$tmp" "$HOME/.claude/cache/usage-limits.json"
fi

green=$'\033[32m'; yellow=$'\033[33m'; red=$'\033[31m'; dim=$'\033[2m'; reset=$'\033[0m'
paint() { # value -> colored "N%"
  local c=$green
  (( $1 >= 60 )) && c=$yellow
  (( $1 >= 80 )) && c=$red
  printf '%s%s%%%s' "$c" "$1" "$reset"
}

sep=" ${dim}·${reset} "
out="$model"
[[ -n "$effort" ]] && out+=" ($effort)"

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
if [[ -n "$branch" ]]; then
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l)
  (( dirty > 0 )) && branch+=" *$dirty"
  out+="${sep}${dir##*/} ($branch)"
else
  out+="${sep}${dir##*/}"
fi

out+="${sep}context $(paint "$ctx")"
[[ -n "$five" ]] && out+="${sep}5h $(paint "$five")"
[[ -n "$week" ]] && out+="${sep}7d $(paint "$week")"
(( added + removed > 0 )) && out+="${sep}${green}+${added}${reset} ${red}−${removed}${reset}"

mins=$(( dur_ms / 60000 ))
if (( mins >= 60 )); then out+="${sep}$(( mins / 60 ))h$(( mins % 60 ))m"
elif (( mins > 0 )); then out+="${sep}${mins}m"; fi

[[ "$cost" != "0" ]] && out+="${sep}$(printf '$%.2f' "$cost")"

printf '%s' "$out"
