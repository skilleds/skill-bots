---
description: schematize-bots — carrega à força TODO o corpo normativo de bots de chat e passa a aplicá-lo nesta sessão.
---
Carregue **agora** o corpo normativo da skill `schematize-bots`. Daqui em diante, nesta sessão, é obrigatório.

1. **Leia na íntegra** `.claude/skills/schematize-bots/references/*.md` (projeto) ou
   `~/.claude/skills/schematize-bots/references/*.md` (global):
   - `credenciais-e-token.md` — cofre, rotação, vazou.
   - `transporte-e-assinatura.md` — webhook x gateway x polling; verificação de assinatura por plataforma.
   - `prazo-fila-rate-limit.md` — ack, fila, buckets, 429, dedupe, sharding.
   - `comandos-intents-permissoes.md` — registro versionado, intents, permissões.
   - `moderacao-entrada-privacidade.md` — entrada hostil, menções, links, LGPD, LLM.
   - `ambientes-e-efeito-externo.md` — servidor de teste, fail-closed, cap.
   - `stack-versoes.md` — anexo volátil com fonte e data.
2. **Rode os gates** no repo atual: `bash .claude/skills/schematize-bots/scripts/check-bot.sh .` e `bash .claude/skills/schematize-bots/scripts/check-bot-effects.sh .`
3. **Aplique** a todo código de bot que escrever ou tocar. **Nunca envie mensagem real**: só bot de
   teste em servidor de teste, e só se `APP_ENV` for explicitamente não-prd.
