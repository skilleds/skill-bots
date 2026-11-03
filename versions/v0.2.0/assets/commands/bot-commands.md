---
description: schematize-bots — desenha o registro versionado de slash commands, intents e permissões mínimas
argument-hint: "<plataforma>"
---

# /bot-commands — comando é contrato, intent é privilégio

Alvo: `${ARGUMENTS}`. Leia `references/comandos-intents-permissoes.md`.

1. **Manifesto versionado** (`commands/*.json|yaml`) com nome, descrição, opções, permissão padrão e escopo.
2. **Script de registro idempotente** (bulk overwrite): guild de teste em dev, global só em prd; roda no CI/deploy, nunca no boot do bot.
3. **Intents**: liste as usadas; cada privilegiada (`MESSAGE_CONTENT`, `GUILD_MEMBERS`, `GUILD_PRESENCES`) com justificativa e alternativa avaliada (slash command e interações dispensam `MESSAGE_CONTENT`).
4. **Permissões** do convite: o mínimo; nunca `Administrator`; comando destrutivo checa papel no servidor, não só no cliente.
5. Mudança incompatível de comando = nova versão no manifesto e nota no CHANGELOG.
