#!/usr/bin/env bash
# PreToolUse guard for custom subagents. Exit 2 blocks the tool call.
set -u

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

block() {
  echo "agent-guard: $1" >&2
  exit 2
}

secret_re='(^|[^[:alnum:]_-])(appsettings[^[:space:]"'"'"']*\.json|\.env([.[:space:]"'"'"']|$)|secrets\.json|[^[:space:]/"'"'"']+\.(pem|pfx|key))'
# Bash commands contain code, where `column.key` / `event.key` are property accesses, not key files.
# So the Bash check leaves out the `.key` extension; file-path checks below still cover it.
bash_secret_re='(^|[^[:alnum:]_-])(appsettings[^[:space:]"'"'"']*\.json|\.env([.[:space:]"'"'"']|$)|secrets\.json|[^[:space:]/"'"'"']+\.(pem|pfx))'

if [[ "$tool" == "Bash" ]]; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
  grep -qE "$bash_secret_re" <<<"$cmd" && block "gizli bilgi dosyalarina Bash ile erisim yasak"
  grep -q 'usage-limit' <<<"$cmd" && block "kullanim limiti verisi yalnizca ana oturuma ait"
  grep -qE '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?(commit|push|reset|rebase|merge|clean|stash|tag)([[:space:]]|$)' <<<"$cmd" \
    && block "git gecmisini degistiren komutlar ana oturuma ait"
  grep -qE 'dotnet[[:space:]]+ef[[:space:]]+database' <<<"$cmd" && block "veritabani migration'i ajana kapali"
  grep -qE '(^|[;&|[:space:]])rm[[:space:]]+-[[:alpha:]]*[rR]' <<<"$cmd" && block "ozyinelemeli silme ajana kapali"
  exit 0
fi

if [[ "$tool" == "Skill" ]]; then
  skill=$(jq -r '.tool_input.skill // ""' <<<"$input")
  [[ "$skill" == "usage-limit" || "$skill" == *":usage-limit" ]] && block "usage-limit skill'i yalnizca ana oturuma ait"
  exit 0
fi

path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""' <<<"$input")
[[ "$path" == *usage-limit* ]] && block "kullanim limiti verisi yalnizca ana oturuma ait"
glob=$(jq -r '.tool_input.glob // .tool_input.pattern // ""' <<<"$input")

if [[ "$tool" == "Read" || "$tool" == "Grep" || "$tool" == "Glob" ]]; then
  grep -qE "$secret_re" <<<"$path" && block "gizli bilgi dosyasi okunamaz: $path"
  if [[ "$tool" != "Read" ]]; then
    grep -qE "$secret_re" <<<"$glob" && block "gizli bilgi dosyasi aranamaz: $glob"
  fi
fi

if [[ "$tool" == "Edit" || "$tool" == "Write" || "$tool" == "NotebookEdit" ]]; then
  grep -qE "$secret_re" <<<"$path" && block "gizli bilgi dosyasi degistirilemez: $path"
  case "$path" in
    */src/app/api/*|src/app/api/*) block "uretilmis API client elle degistirilemez; ng-openapi-gen kullan" ;;
    */VERSION|VERSION|*/CHANGELOG.md|CHANGELOG.md) block "VERSION ve CHANGELOG ana oturuma ait" ;;
  esac
fi

exit 0
