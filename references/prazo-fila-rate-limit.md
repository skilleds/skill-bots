# Prazo, fila, rate limit, dedupe e sharding

> Parte da skill **schematize-bots**.

## 1. Prazo da plataforma
- **Discord interactions**: resposta inicial em **3 s** ou o token é invalidado; para trabalho longo,
  responda `DEFERRED_*` e depois envie follow-up (token válido por **15 min**).
- **Slack**: responda `2xx` rápido (prática: 3 s) e processe fora; retries chegam com `X-Slack-Retry-Num`.
- **Telegram webhook**: responda `200` rápido; falha repetida faz o Telegram reenviar e acumular updates.
- **WhatsApp**: `200` rápido; reentregas por até dias com backoff.
Padrão: **handler = verificar, deduplicar, enfileirar, responder**; worker faz o resto (LLM, banco, API externa).

## 2. Rate limit
- Limites são **por rota/bucket**, não globais. Discord devolve `X-RateLimit-*` e `X-RateLimit-Bucket`;
  `429` traz `Retry-After` e o campo `global`. Slack: tiers por método e `Retry-After` em segundos;
  `chat.postMessage` ~1 msg/s/canal. Telegram: ~1 msg/s por chat, 20 msg/min em grupo, ~30 msg/s para usuários diferentes.
- Cliente de saída com **fila por bucket**, backoff exponencial com jitter e `Retry-After` obedecido.
  Laço `for` de envio sem tratamento de `429` é o defeito que o gate acusa.
- Reincidência em 429 vira ban temporário de IP (Discord: muitos 401/403/429 em 10 min) — monitore.
- Difusão em massa: espalhe no tempo; para Telegram, broadcast pago só com os requisitos da plataforma.

## 3. Idempotência
Dedupe persistente (Redis com TTL ou tabela com chave única): `update_id` (Telegram, sequencial: guarde o último),
`id` da interaction (Discord), `event_id` (Slack), `id` da mensagem (WhatsApp). Efeito colateral (envio,
cobrança, moderação) só após marcar o id.

## 3.1 Fila durável e resiliência (piso 28 da engineering)
O ack no prazo só é seguro com **inbox durável**: grave `interaction_id`/`update_id` + payload (DB/Redis
persistente, NUNCA memória) e só depois responda o ack; dedupe com TTL **maior** que a janela de reentrega
da plataforma. Retry com backoff+jitter, **DLQ** para mensagem envenenada, shutdown gracioso que drena o
em voo. Matriz mínima de teste (também em `/bot-review`): (1) boot com dependências fora; (2) 5xx/timeout
do destino ⇒ item na fila, bot vivo; (3) reinício com fila cheia ⇒ drena sem perda nem duplicata;
(4) reentrega idempotente; (5) envenenada ⇒ DLQ após N tentativas; (6) shutdown sem perda; (7) crash entre
persistir e confirmar ⇒ sem perda. Gate da base: `check-resilience.sh`.

## 4. Sharding e escala
Discord: sharding obrigatório a partir de **2.500 guilds** por shard; gateway reconecta com resume;
Slack/Telegram escalam por réplicas stateless atrás de fila. Observabilidade (`schematize-observability`):
latência de ack, tamanho da fila, taxa de 429, reconexões, shards desconectados.
