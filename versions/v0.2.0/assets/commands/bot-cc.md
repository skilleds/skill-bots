---
description: schematize-bots — context compact: grava o handoff no archive e roda /compact.
---
Antes de compactar, **grave o handoff** em `<projeto>/<projeto>_archive/context/` no par
**context + checklist** do padrão da `schematize-archive` (prefixo `AAAA-MM-DD-<slug>-`), FEITO vs
ABERTO. Inclua: bots desenhados ou revisados, achados do `scripts/check-bot.sh` ainda abertos,
exceções (`bot-ok:`) com o motivo, decisões pendentes (transporte, intents) e o que depende de
humano. Nunca inclua token, segredo ou dado pessoal. Só então rode `/compact`.
