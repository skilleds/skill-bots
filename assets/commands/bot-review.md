---
description: schematize-bots — revisa um bot contra o piso: roda o gate e depois lê o que a máquina não lê
argument-hint: "<caminho do bot>"
---

# /bot-review

Alvo: `${ARGUMENTS}` (default: repo atual).

1. `bash .claude/skills/schematize-bots/scripts/check-bot.sh ${ARGUMENTS:-.}` e `.../check-external-effects.sh ${ARGUMENTS:-.}` (piso 18) — trate rc `1` como reprovação e `2` como "nada verificado".
2. Leia o que o gate não lê: token só no cofre e rotação documentada; transporte adequado; ack no prazo com trabalho em fila;
   buckets de rate limit por rota (não um limitador global cego); dedupe persistente; checagem de papel no servidor
   em comando destrutivo; retenção e apagamento; teste contra dublê, nunca canal real; bot de teste separado.
3. Reporte por piso (número do SKILL.md), com `arquivo:linha` e a correção. Nada de elogio vazio.
