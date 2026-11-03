# Changelog — schematize-bots

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [0.2.0] — 2026-11-03
### Adicionado
- `scripts/check-bot-effects.sh` (+ teste vermelho→verde): gate do piso 18 (provider default = sink, guard dentro do provider fail-closed, allowlist, cap `BOT_MAX_MSGS_PER_RUN`, token de prd em env não-prd).
- Piso 28 (inbox durável + matriz de 7 testes) e piso 20 (matriz da rota de webhook); bloco herdado pisos 22–29.
### Alterado
- Gate do piso 18 renomeado `check-external-effects.sh` -> `check-bot-effects.sh` (+ `.test.sh`): o nome antigo é da cópia canônica herdada da engineering (restaurada por `sync-herdados`). `check-bot.sh` agora CHAMA `check-bot-effects.sh`: rodar o gate principal já cobre o efeito externo (rc 2 do auxiliar não reprova).
### Corrigido
- Citação "piso 1" para efeito externo ⇒ piso 18 da engineering.
- `check-bot.sh`: comentário não prova verificação de assinatura/429/secret_token; `ENVIO_RE` cobre `user.send`, `followup.send`, `.reply`; `TOKEN_RE` cobre WhatsApp `EAA`, Matrix `syt_`, Slack `xoxe`, Discord com prefixo livre.
- README: clone sem `/tmp` fixo; gate por commit é local, CI remoto só antes do hml (piso 27).
- [~] Reverificar em fonte primária os itens "secundário" de `stack-versoes.md` (WhatsApp janela 24 h/templates, Matrix E2EE): não confirmado nesta onda.
- `check-bot-effects.sh`: `trap ... EXIT` remove o temporário do loop mesmo com Ctrl-C.
## [0.1.0] — 2026-10-14
Primeira versão. Bot é um processo com credencial de longa vida, entrada pública e efeito externo em
massa (mensagem em canal real, menção a todos): token commitado, webhook sem assinatura, `@everyone`
ecoado de entrada de usuário e loop de envio sem tratamento de 429 são incidentes recorrentes e não
tinham dono nem gate no catálogo.

### Adicionado
- `SKILL.md` com 14 pisos e fronteiras com api, ai, iam, payments, infra/docker, observability, git, incident.
- `references/`: `credenciais-e-token`, `transporte-e-assinatura`, `prazo-fila-rate-limit`, `comandos-intents-permissoes`, `moderacao-entrada-privacidade`, `ambientes-e-efeito-externo`, `stack-versoes` (anexo volátil com fonte e data).
- `scripts/check-bot.sh` + `check-bot.test.sh`: 6 regras estáticas (token literal, webhook sem assinatura, eco sem allowed_mentions, envio em loop sem 429, intent privilegiada sem justificativa, setWebhook sem secret_token), waiver `bot-ok:`.
- Comandos: `bot-help`, `bot-load`, `bot-new`, `bot-review`, `bot-webhook`, `bot-commands`, `bot-moderation`, `bot-claude`, `bot-handoff`, `bot-cc`.
