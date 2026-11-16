---
name: usage-limit
description: Claude kullanım limitinin (5 saatlik ve 7 günlük) ne kadarının dolduğunu gösterir ve ajan seçimini buna göre ayarlar. Yalnızca ana oturum içindir, subagent kullanmaz. Pahalı bir iş dağıtmadan önce (architect, debugger, heavy ajan, birden fazla ajanlı iş) veya kullanıcı kalan limiti sorduğunda kullan.
allowed-tools: Bash(~/.claude/skills/usage-limit/usage.sh)
---

# Kullanım limiti

Bu skill yalnızca kullanıcıyla doğrudan konuşan ana oturum içindir. Subagent olarak çalışıyorsan kullanma; limit bilgisi senin işini nasıl yapacağını değiştirmez.

## 1. Durumu oku

```bash
~/.claude/skills/usage-limit/usage.sh
```

Veri, durum satırı betiğinin (`~/.claude/statusline.sh`) son yazdığı anlık görüntüdür. "Verinin yaşı" 10 dakikadan büyükse rakamların eski olabileceğini kullanıcıya söyle. "Veri yok" çıkarsa limite göre karar verme, normal çalış ve bunu belirt.

## 2. Ajan seçimini ayarla

5 saatlik ve 7 günlük yüzdelerden yüksek olanı esas al.

| Dolan | Ne yap |
|---|---|
| %60'ın altı | Normal çalış. Kullanıcı sormadıysa limitten söz etme. |
| %60–80 | Light ajanları tercih et. Heavy ajan veya `architect` gerekiyorsa çağır, ama raporda limitin durumunu bir cümleyle belirt. |
| %80 ve üstü | `architect`, `debugger`, heavy ajan veya birden fazla ajan başlatmadan önce kullanıcıya sor: yüzdeyi ve sıfırlanma saatini söyle, işi şimdi yapmayı ya da sıfırlanma sonrasına bırakmayı öner. Küçük işleri light ajanla veya kendi küçük düzeltme yetkinle sürdür. |

## 3. Yapma

- Limiti gerekçe gösterip bir ajandan doğrulamayı atlamasını, işi yarım bırakmasını veya daha az dikkatli çalışmasını isteme. Tasarruf, hangi ajanın çağrıldığından gelir; işin nasıl yapıldığından değil.
- Limit rakamlarını ajan görev tanımlarına yazma.
- Kullanıcının açıkça istediği bir işi limit yüzünden kendi kararınla erteleme; öner, kararı kullanıcı versin.
