#!/usr/bin/env bash
# PostToolUse hook: after an i18n JSON file is edited, run the repo's key-parity check.
# Exit 2 sends the check output back to Claude so it fixes the missing key right away.
set -u

path=$(jq -r '.tool_input.file_path // ""')
case "$path" in
  */i18n/*.json) ;;
  *) exit 0 ;;
esac

dir=$(dirname "$path")
while [[ "$dir" != "/" && ! -f "$dir/package.json" ]]; do dir=$(dirname "$dir"); done
[[ -f "$dir/package.json" ]] || exit 0
grep -q '"i18n:check"' "$dir/package.json" || exit 0

if ! out=$(cd "$dir" && npm run --silent i18n:check 2>&1); then
  echo "i18n:check basarisiz ($path duzenlendikten sonra). tr/en key esitligini duzelt:" >&2
  echo "$out" | tail -n 30 >&2
  exit 2
fi
exit 0
