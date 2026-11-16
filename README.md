# Claude Code ortak yapılandırması

Bir backend API reposu ve iki Angular frontend reposundan oluşan çok repolu bir projede Claude Code ile çalışırken kullanılan kullanıcı düzeyi ayarlar: çalışma modeli, ajanlar, koruma hook'ları, durum satırı ve kullanım limiti skill'i.

Repoya özel kurallar burada değil, her reponun kendi `CLAUDE.md`, `.claude/rules/` ve `.claude/skills/` klasöründedir.

## Kurulum

```bash
git clone https://github.com/tkeremc/claude-config.git ~/claude-config
cd ~/claude-config && ./install.sh
```

`install.sh` dosyaları `~/.claude` altına kopyalar ve değiştirdiği her şeyi önce `~/.claude/backups/install-<tarih>/` altına yedekler:

- `agents/`, `hooks/`, `skills/usage-limit/`, `statusline.sh` kopyalanır.
- `CLAUDE.md` sende yoksa kopyalanır; varsa ekip sürümü `CLAUDE.team.md` olarak yanına konur, elle birleştirirsin.
- `settings.json` içinden yalnızca `hooks`, `statusLine` ve izin kuralları seninkine eklenir; model, tema ve plugin ayarların korunur.

Gerekenler: `bash` ve `jq`. Betikler Linux'ta denendi; macOS ve Windows'ta (Git Bash) denenmedi. Masaüstü bildirimi yalnızca `notify-send` varsa çalışır.

Güncellemek için `git pull` ardından yeniden `./install.sh`.

## İçerik

| Yol | Ne işe yarar |
|---|---|
| `CLAUDE.md` | Çalışma modeli (ana oturum yönetir, ajanlar kod yazar), ajan seçimi, görsel kontrol kuralı, çalışma ilkeleri |
| `agents/` | `architect`, `security`, `frontend-light`, `frontend-heavy`, `backend-light`, `backend-heavy`, `debugger` |
| `hooks/agent-guard.sh` | Ajanlar için koruma: gizli dosyalar, git geçmişini değiştiren komutlar, `dotnet ef database`, özyinelemeli silme, `VERSION`/`CHANGELOG.md`/`src/app/api/` düzenlemesi, `usage-limit` skill'i |
| `hooks/i18n-check.sh` | Bir `i18n/*.json` dosyası düzenlenince reponun `npm run i18n:check` komutunu çalıştırır |
| `skills/usage-limit/` | Kullanım limitini okur ve pahalı ajanları çağırmadan önce ne yapılacağını söyler; yalnızca ana oturum kullanır |
| `statusline.sh` | Durum satırı: model, klasör ve dal, context, 5 saatlik ve 7 günlük limit, satır değişimi, süre, maliyet |
| `settings.json` | Hook kayıtları, durum satırı ve izin kuralları (kişisel alanlar da içerir; kurulum yalnızca ortak olanları alır) |

## Varsayımlar

- Repolar aynı üst klasörde yan yana durur. Ajanlar repoları rolleriyle anar (backend API, admin panel, sales portal); klasör adlarını `~/.claude/rules/workspace.md` dosyasına kendin yazarsın. Bu dosya git'e girmez. Örnek: `| Backend API repo (.NET) | ~/Projects/<klasör> |` biçiminde üç satırlık bir tablo.
- Her oturum, üzerinde çalışılan reponun içinden başlatılır.
