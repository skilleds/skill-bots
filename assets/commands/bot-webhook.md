---
description: schematize-bots — cria ou audita o receptor de interações/webhook do bot (assinatura, replay, ack, fila, dedupe)
argument-hint: "<plataforma ou caminho do handler>"
---

# /bot-webhook — assinatura antes de tudo, ack antes do resto

Alvo: `${ARGUMENTS}`. Leia `references/transporte-e-assinatura.md` e `prazo-fila-rate-limit.md`.

1. **Corpo bruto** (nunca o JSON reparseado) para a assinatura.
2. **Verifique**: Discord Ed25519 (`X-Signature-Ed25519` + `X-Signature-Timestamp`, chave pública do app) e responda PING;
   Telegram `X-Telegram-Bot-Api-Secret-Token` igual ao `secret_token` do `setWebhook` (tempo constante);
   Slack `v0=` HMAC-SHA256 de `v0:<ts>:<corpo>` com janela de 5 min; WhatsApp `X-Hub-Signature-256` com o app secret.
   Falha = `401`, métrica, alerta.
3. **Dedupe** persistente por id (`update_id`, interaction id, `event_id`).
4. **Ack no prazo** e enfileire o trabalho; resposta tardia usa o token de follow-up (Discord: 15 min).
5. **Testes** contra dublê: assinatura inválida, timestamp velho, corpo alterado, evento repetido N vezes, PING.
6. **Matriz de acesso (piso 20)**: a rota do bot é pública por definição; entra na matriz (schematize-qa) com anônimo sem assinatura ⇒ `401` sem corpo útil, método trocado, path alternativo, assinatura de outro ambiente ⇒ `401`, rota debug/metrics ausente; M == N com o inventário de rotas (`check-route-authz.sh`).
Audite com `bash .claude/skills/schematize-bots/scripts/check-bot.sh .` (`bot-webhook-sem-assinatura`, `bot-telegram-sem-secret-token`).
Contrato genérico de webhook: `schematize-api`.
