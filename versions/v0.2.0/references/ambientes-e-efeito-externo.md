# Ambientes e efeito externo

> Parte da skill **schematize-bots**. Herda `schematize-engineering → references/efeitos-externos.md`.

Mensagem em canal, DM e menção são efeito externo irreversível (a mensagem já foi lida, notificou gente).
- **Fail-closed**: `APP_ENV` ausente/desconhecido ⇒ não-prd. Só `prd` exato usa o token de produção.
- **Bots separados**: aplicação de dev/teste distinta da de prd, instalada **só** em servidor/workspace/canal de teste
  da casa; WhatsApp: número de teste da Meta com destinatários allowlistados; Telegram: bot de teste e chat privado do time.
- **Nunca** DM a usuário real, canal de comunidade real ou contato real fora de prd; fixtures usam ids sintéticos.
- **Cap por execução** de mensagens com abort; modo `--dry-run` que só loga o que enviaria.
- Testes automatizados rodam contra dublê do cliente HTTP/gateway; teste E2E em servidor de teste.
- **Provider default = SINK.** O envio real vive num provider único; o `OutboundGuard` fica DENTRO dele (não no
  chamador): `APP_ENV` ausente/dev/"prod" ambíguo ⇒ sink; só `prd` exato envia; fora de prd, destino fora de
  `BOT_TEST_ALLOWLIST` ⇒ erro; cap `BOT_MAX_MSGS_PER_RUN` (substitui `MAIL_MAX_PER_RUN`, que é de e-mail).
  Prova: `scripts/check-bot-effects.sh` (regras `bot-envio-sem-guard`, `bot-sem-sink`, `bot-default-prd`,
  `bot-guard-nao-fail-closed`, `bot-prd-em-nao-prd`) + teste de unidade do guard. Piso 18 da engineering, não "piso 1".
- Exceção (entregar de verdade fora de prd) exige as cinco condições da base (ADR + allowlist ≤5 + cap + janela + isolamento).
