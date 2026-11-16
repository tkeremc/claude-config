#!/usr/bin/env bash
# Installs this shared Claude Code configuration into ~/.claude on another machine.
# Usage: clone the repo anywhere, then run ./install.sh
# Needs: bash, jq. Existing files are backed up to ~/.claude/backups/install-<timestamp>/ before being replaced.
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
dst="$HOME/.claude"

if [[ "$src" == "$dst" ]]; then
  echo "Bu klasör zaten ~/.claude; kurulacak bir şey yok."
  exit 0
fi
command -v jq >/dev/null || { echo "jq gerekli, önce onu kur." >&2; exit 1; }

backup="$dst/backups/install-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dst" "$backup"

copy() { # relative path (file or directory)
  local rel=$1
  if [[ -e "$dst/$rel" ]]; then
    mkdir -p "$backup/$(dirname "$rel")"
    cp -a "$dst/$rel" "$backup/$rel"
  fi
  mkdir -p "$dst/$(dirname "$rel")"
  cp -a "$src/$rel" "$dst/$(dirname "$rel")/"
  echo "kuruldu: $rel"
}

copy agents
copy hooks
copy skills/usage-limit
copy statusline.sh
chmod +x "$dst/hooks/"*.sh "$dst/statusline.sh" "$dst/skills/usage-limit/usage.sh"

# CLAUDE.md: never overwrite a personal one silently.
if [[ -e "$dst/CLAUDE.md" ]] && ! cmp -s "$src/CLAUDE.md" "$dst/CLAUDE.md"; then
  cp -a "$src/CLAUDE.md" "$dst/CLAUDE.team.md"
  echo "CLAUDE.md zaten var: ekip sürümü CLAUDE.team.md olarak kopyalandı, elle birleştir."
else
  copy CLAUDE.md
fi

# settings.json: merge only the shared keys (hooks, statusLine, permission rules); keep personal ones (model, theme, plugins).
if [[ -e "$dst/settings.json" ]]; then
  cp -a "$dst/settings.json" "$backup/settings.json"
  jq -s '
    .[0] as $mine | .[1] as $team |
    $mine
    | .hooks = $team.hooks
    | .statusLine = $team.statusLine
    | .permissions.allow = ((($mine.permissions.allow // []) + ($team.permissions.allow // [])) | unique)
    | .permissions.deny  = ((($mine.permissions.deny  // []) + ($team.permissions.deny  // [])) | unique)
  ' "$dst/settings.json" "$src/settings.json" > "$dst/settings.json.new"
  mv "$dst/settings.json.new" "$dst/settings.json"
  echo "settings.json: hooks, statusLine ve izin kuralları birleştirildi; kişisel ayarların korundu."
else
  jq '{permissions: {allow: .permissions.allow, deny: .permissions.deny}, hooks, statusLine}' "$src/settings.json" > "$dst/settings.json"
  echo "kuruldu: settings.json (yalnızca ortak anahtarlar)"
fi

echo
echo "Bitti. Yedekler: $backup"
echo "Yeni bir Claude Code oturumu aç; /agents ile ajanları, /context all ile yüklenen dosyaları kontrol et."
