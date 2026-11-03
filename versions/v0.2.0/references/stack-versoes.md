# Anexo volátil — plataformas de bot

> Parte da skill **schematize-bots**. **Verificado em: 2026-10-14.** Cadência: trimestral e antes de cada release.
> Método: WebFetch em fonte primária quando abriu; senão WebSearch (marcado "secundário").

| Plataforma | Fato | Fonte | Situação |
|---|---|---|---|
| Telegram | Bot API **10.3**, 2026-08-24 | core.telegram.org/bots/api-changelog | primário |
| Telegram | ~1 msg/s por chat; 20 msg/min em grupo; ~30 msg/s para usuários distintos; broadcast pago até 1000 msg/s (0,1 Stars/msg acima de 30/s; exige 100.000 Stars e 100.000 MAU) | core.telegram.org/bots/faq | primário |
| Telegram | `secret_token` 1-256 chars `A-Za-z0-9_-`, cabeçalho `X-Telegram-Bot-Api-Secret-Token` | docs de bibliotecas (aiogram) | secundário <!-- reverificar --> |
| Discord | Interactions: resposta inicial em 3 s; token de follow-up 15 min | docs.discord.com/developers/interactions/receiving-and-responding | primário |
| Discord | Gateway `v=10`; intents privilegiadas `GUILD_PRESENCES`, `GUILD_MEMBERS`, `MESSAGE_CONTENT`; verificação em 100+ guilds; sharding a partir de 2.500 guilds/shard | docs.discord.com/developers/events/gateway | primário |
| Discord | Verificação Ed25519 (`X-Signature-Ed25519`, `X-Signature-Timestamp`), `401` se inválida | libs oficiais (discord-interactions) | secundário <!-- reverificar na doc primária --> |
| Slack | Assinatura `v0=` HMAC-SHA256 de `v0:<ts>:<corpo>`; exemplo oficial rejeita timestamp > 5 min | docs.slack.dev/authentication/verifying-requests-from-slack | primário |
| Slack | Tiers 1-4 (1+, 20+, 50+, 100+ /min); `chat.postMessage` ~1/s/canal; `Retry-After` em 429; limites novos de `conversations.history` para apps comerciais fora do Marketplace desde 2025-05-29 | docs.slack.dev/apis/web-api/rate-limits | primário |
| Slack | Prazo de 3 s para ack de evento | blog de terceiros | secundário <!-- reverificar --> |
| WhatsApp Cloud API | `X-Hub-Signature-256` HMAC-SHA256 do app secret; cobrança por mensagem desde 2025-07-01 | guias de terceiros | secundário <!-- reverificar na doc da Meta --> |
| Graph API (Meta) | **v26.0**, 2026-07-29 | developers.facebook.com/docs/graph-api/changelog | primário |
| Matrix | Spec **v1.19**, 2026-07-08 (v1.18 em 2026-03-26) | matrix.org/blog/category/releases | secundário <!-- reverificar em spec.matrix.org --> |

## Não verificado
Limites exatos de rate limit do Discord por rota (dinâmicos, lidos dos cabeçalhos); preços do WhatsApp; ban de IP do
Discord por 429/401 (10.000 requisições inválidas em 10 min, citado de memória) <!-- reverificar -->; Matrix 2.0.
