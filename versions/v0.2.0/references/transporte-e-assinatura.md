# Transporte e assinatura

> Parte da skill **schematize-bots**. O contrato genérico de webhook é da `schematize-api`.

## 1. Webhook/HTTP x gateway x long polling
| Transporte | Quando | Cuidados |
|---|---|---|
| **Webhook / interactions HTTP** | serverless, picos, bot só de comandos, sem estado | assinatura obrigatória; ack no prazo; endpoint público e HTTPS |
| **Gateway (WebSocket)** | precisa de eventos de mensagem, presença, voz, estado em memória (Discord) | heartbeat, resume, sharding, intents; processo de longa vida |
| **Long polling** (`getUpdates`) | dev, atrás de NAT, volume baixo | um consumidor só; sem webhook ativo ao mesmo tempo (Telegram) |
Slack: Events API (HTTP) ou Socket Mode (WebSocket, sem URL pública). Matrix: appservice (HTTP,
`hs_token`) ou cliente com `/sync`. WhatsApp Cloud API: só webhook.

## 2. Verificação por plataforma (corpo BRUTO, comparação em tempo constante)
- **Discord interactions**: cabeçalhos `X-Signature-Ed25519` e `X-Signature-Timestamp`; verifique a
  assinatura sobre `timestamp + corpo bruto` com a chave pública do app; inválida = `401`. Responda o PING (type 1).
  Discord testa o endpoint com assinaturas inválidas ao salvar a URL.
- **Telegram**: passe `secret_token` (1-256 chars, `A-Za-z0-9_-`) no `setWebhook`; confira o cabeçalho
  `X-Telegram-Bot-Api-Secret-Token` em todo POST. Use `allowed_updates` mínimo. URL do webhook com caminho imprevisível é defesa extra, não substituta.
- **Slack**: `X-Slack-Signature` = `v0=` + HMAC-SHA256(signing secret, `v0:<X-Slack-Request-Timestamp>:<corpo>`);
  rejeite timestamp a mais de 5 minutos do relógio local (replay). Responda `url_verification` (challenge) só após verificar.
- **WhatsApp Cloud API**: `X-Hub-Signature-256: sha256=<hex>` = HMAC-SHA256(app secret, corpo); handshake `hub.verify_token`
  só no GET de inscrição.
- **Matrix appservice**: `hs_token` no pedido do homeserver, comparado em tempo constante.

## 3. Erros comuns
Reparsear o JSON antes de verificar; comparar com `==`; aceitar sem timestamp; tratar o `secret_token`
como opcional; verificar só em prd (o teste passa a mentir). O gate `check-bot.sh` acusa handler sem
verificação e `setWebhook` sem `secret_token`.
