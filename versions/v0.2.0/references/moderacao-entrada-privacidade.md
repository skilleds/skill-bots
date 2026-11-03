# Moderação, entrada não confiável e privacidade

> Parte da skill **schematize-bots**.

## 1. Entrada é hostil
- **Menções**: ao ecoar texto de usuário, `allowed_mentions: {parse: []}` (Discord); no Slack escape `<!channel>`/`<!here>`;
  sem isso, `@everyone` vira spam em massa pelo bot.
- **Markdown/embeds**: escape; trunque ao limite da plataforma (Discord 2000 chars de conteúdo); campo de embed vindo de usuário é texto, não markup de autoridade.
- **Links**: allowlist de domínio; ao buscar URL (preview), barre SSRF (IP privado, link-local, metadata de nuvem, redirects).
- **Comandos**: validação de tipo/tamanho das opções no servidor; autorização por papel no servidor.
- **Anti-abuso**: cooldown por usuário e por guild, limite de entrada, blocklist, denúncia.

## 2. LGPD
Guarde **ids, não conteúdo**; se precisar do conteúdo, finalidade e base legal declaradas, retenção curta
(dias, não anos), `/optout` e apagamento a pedido, minimização em log e analytics. Menor de idade:
plataformas têm idade mínima; o bot não coleta dado sensível. Texto da política: `schematize-institutional`.

## 3. Bot com LLM
Mensagem de chat é entrada de prompt injection: ferramentas mínimas, nada de ação destrutiva sem confirmação humana,
saída sem menções, teto de tokens/custo por usuário e guild. Detalhe: `schematize-ai → /ai-guardrails`.
