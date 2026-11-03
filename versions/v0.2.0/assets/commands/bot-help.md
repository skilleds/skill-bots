---
description: Mapa da skill schematize-bots (bots de chat — token, assinatura, ack, rate limit, moderação; nunca mensagem real fora de prd).
---
**schematize-bots** — bot é credencial de longa vida com entrada pública e efeito externo em massa. Piso 1: nunca mensagem real fora de prd.

| Comando | O que faz |
|---|---|
| `/bot-help` | esta lista |
| `/bot-load` | carrega à força TODO o corpo normativo e passa a aplicá-lo |
| `/bot-new` | scaffold de bot novo (plataforma, transporte, token, comandos, ambientes, gate) |
| `/bot-review` | revisa um bot: roda `scripts/check-bot.sh` e lê o que a máquina não lê |
| `/bot-webhook` | cria ou audita o receptor de interações/webhook |
| `/bot-commands` | registro versionado de slash commands, intents e permissões |
| `/bot-moderation` | moderação, anti-abuso, menções, links, privacidade |
| `/bot-claude` | cria ou mescla o `CLAUDE.md` sempre-on de bots na raiz do repo |
| `/bot-cc` · `/bot-handoff` | context compact / handoff no archive |

Pareia com: `schematize-api` (webhook genérico), `schematize-ai` (LLM), `schematize-iam` (vincular conta),
`schematize-payments` (cobrança), `schematize-infra`/`docker` (deploy), `schematize-observability`, `schematize-git`.
