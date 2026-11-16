#!/usr/bin/env bash
# Prints the last usage-limit snapshot written by ~/.claude/statusline.sh.
f="$HOME/.claude/cache/usage-limits.json"
if [[ ! -s "$f" ]]; then
  echo "Veri yok: durum satırı henüz limit bilgisi yazmadı (hesap bu alanı vermiyor olabilir)."
  exit 0
fi

fmt_reset() { # epoch seconds or ISO string -> local time
  local v=$1
  [[ -z "$v" || "$v" == "null" ]] && { echo "bilinmiyor"; return; }
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    (( v > 100000000000 )) && v=$(( v / 1000 ))
    date -d "@$v" '+%d.%m %H:%M'
  else
    date -d "$v" '+%d.%m %H:%M' 2>/dev/null || echo "$v"
  fi
}

line() { # label key
  local used reset
  used=$(jq -r ".$2.used_percentage | if . == null then empty else round end" "$f")
  [[ -z "$used" ]] && return
  reset=$(jq -r ".$2.resets_at // empty" "$f")
  printf '%s: %%%s kullanıldı, %%%s kaldı, sıfırlanma %s\n' "$1" "$used" "$(( 100 - used ))" "$(fmt_reset "$reset")"
}

line "5 saatlik" five_hour
line "7 günlük" seven_day

age=$(( $(date +%s) - $(jq -r '.written_at // 0' "$f") ))
echo "Verinin yaşı: $(( age / 60 )) dk"
