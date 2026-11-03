---
description: schematize-bots — gera o handoff (context.md + checklist.md) no archive, sem compactar.
---
Gere o handoff em `<projeto>/<projeto>_archive/context/`: `AAAA-MM-DD-<slug>-context.md` (o que foi
feito, plataforma e transporte escolhidos, o que o gate acusou, estado dos comandos registrados) e
`AAAA-MM-DD-<slug>-checklist.md` (FEITO vs ABERTO, nas três classes da casa: `- [ ]` máquina ·
`- [H ]` humano · `- [~]` on-hold). Não compacte — só grave. Nunca grave token de bot, signing secret,
chave pública privada, id de usuário real ou conteúdo de mensagem no handoff.
