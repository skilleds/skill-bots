---
description: schematize-bots — moderação, anti-abuso, menções, links e privacidade das mensagens do bot
argument-hint: "<bot ou fluxo>"
---

# /bot-moderation — entrada hostil, dado mínimo

Alvo: `${ARGUMENTS}`. Leia `references/moderacao-entrada-privacidade.md`.

1. **Ao ecoar texto de usuário**: `allowed_mentions` restrito (`parse: []`), escape de markdown e de embed, truncamento.
2. **Links**: allowlist de domínio; nunca buscar URL de usuário sem barrar SSRF (IP privado, metadata, redirect).
3. **Anti-abuso**: rate limit por usuário/guild, cooldown de comando, tamanho máximo de entrada, bloqueio e denúncia.
4. **Privacidade (LGPD)**: tabela do que guarda (id, não conteúdo), base legal, retenção, opt-out (`/optout`), apagamento a pedido.
5. **LLM no bot**: `schematize-ai` (injection, guardrails, teto de custo por usuário).
6. Nada de conteúdo de mensagem em log ou analytics (`schematize-analytics`).
