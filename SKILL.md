---
name: schematize-bots
metadata:
  version: 0.1.0
description: >-
  Bots Discord, Telegram, Slack, WhatsApp e Matrix: token em cofre, webhook assinado, ack e fila, 429, intents mínimas. Use ao criar ou revisar bot. Gate check-bot.sh. LLM: schematize-ai.
---
<!-- cross-skill: efeitos-externos.md, iam.md -> schematize-engineering -->

# Bots e utilitários de chat (schematize-bots)

Disciplina normativa para **criar, operar e auditar bot** em Discord, Telegram, Slack, WhatsApp
Business (Cloud API) e Matrix. A tese: **bot é uma credencial de longa vida com entrada pública e
efeito externo em massa**. Quem commita o token, aceita webhook sem checar assinatura, ecoa texto de
usuário com `@everyone`, ignora o `429` ou testa em canal real está a um deploy do incidente.

**Versão:** skill `schematize-bots` v0.1.0. Changelog em `CHANGELOG.md`.

## Precedência e herança (leia antes de divergir)

<!-- herdado:engineering/precedencia:dominio intro="Esta skill é o recorte **bots de chat (Discord, Telegram, Slack, WhatsApp Business, Matrix)** de um **domínio de integração**: independe de linguagem e vale em qualquer serviço do rol (`schematize-engineering` → `references/linguagens.md`), escolhido por fit + ADR." cmd="bot" -->Esta skill é o recorte **bots de chat (Discord, Telegram, Slack, WhatsApp Business, Matrix)** de um **domínio de integração**: independe de linguagem e vale em qualquer serviço do rol (`schematize-engineering` → `references/linguagens.md`), escolhido por fit + ADR.

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização do domínio ou da
   ferramenta — o como, o padrão, o gate. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Esta skill herda os pisos da base e
   os comandos dela cobrem o **domínio**, não o piso geral. Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/bot-*` cobrem o domínio desta skill; o piso geral é o da base.<!-- /herdado -->

## Fronteira com as outras skills

| Assunto | Dono | Ponteiro |
|---|---|---|
| **Bot de chat**: token, transporte (webhook x gateway x polling), assinatura da plataforma, ack no prazo, rate limit, comandos, intents, moderação, privacidade, não mandar mensagem real fora de prd | **esta skill** | `references/*.md` abaixo |
| Webhook **genérico** (contrato, HMAC, retry, replay window, SSRF) | `schematize-api` | `/api-webhook`; aqui só as assinaturas específicas de cada plataforma |
| LLM dentro do bot (prompt injection, custo, guardrails, evals) | `schematize-ai` | `/ai-guardrails`; aqui só onde a entrada do chat entra no prompt |
| Vincular a conta do usuário ao bot (OAuth "Entrar com Discord/Slack", `/link`) | `schematize-iam` | aqui só o gatilho; identidade do bot ≠ identidade do usuário |
| Cobrança ou assinatura vendida pelo bot | `schematize-payments` | `/pay-flow`; o bot nunca toca PAN nem cobra fora de prd |
| Deploy, cofre, rede, systemd | `schematize-infra` | `/infra-secrets`; aqui o que o bot exige |
| Imagem, container do bot | `schematize-docker` | `/docker-harden` |
| Métrica, SLO, alerta (latência de ack, 429, shard caído) | `schematize-observability` | aqui o que medir |
| Token commitado | `schematize-git` | `/git-leak`: rotacionar primeiro |
| Bot fora do ar, spam em massa disparado, token vazado: resposta | `schematize-incident` | declarar SEV, mitigar |
| Teste (pirâmide, dublê) e ataque (forja de interaction, replay) | `schematize-qa` · `schematize-pentest` | aqui o que provar |
| Evento de uso do bot (tracking plan, sem conteúdo de mensagem) | `schematize-analytics` | |
| Termos, privacidade, política de retenção publicada | `schematize-institutional` | aqui só o gatilho técnico |
| Efeito externo fora de prd (base) | `schematize-engineering → references/efeitos-externos.md` | herdado, piso 18 da engineering |

## Comandos (Claude Code)

| Comando | O que faz |
|---|---|
| `/bot-help` | lista os comandos |
| `/bot-load` | carrega à força o corpo normativo |
| `/bot-new` | scaffold de bot novo: plataforma, transporte, token, comandos, ambientes, gate |
| `/bot-review` | revisa um bot: roda o gate e lê o que a máquina não lê |
| `/bot-webhook` | cria ou audita o receptor de interações/webhook (assinatura, replay, ack, fila, dedupe) |
| `/bot-commands` | desenha o registro versionado de slash commands, intents e permissões mínimas |
| `/bot-moderation` | moderação, anti-abuso, menções, links e privacidade das mensagens |
| `/bot-claude` | cria/mescla o `CLAUDE.md` sempre-on na raiz do repo |
| `/bot-cc` · `/bot-handoff` | context compact / handoff arquivado |

## Como usar

1. **Rode os gates:** `bash scripts/check-bot.sh .` e `bash scripts/check-external-effects.sh .` (piso 18 da
   engineering: sink por default, guard dentro do provider, cap `BOT_MAX_MSGS_PER_RUN`, allowlist `BOT_TEST_ALLOWLIST`) —
   `0` passa · `1` reprova · `2` nada para verificar (não é aprovação). Estático, sem dependência de linguagem ou
   SDK; waiver `bot-ok: <motivo>`. Gate por commit é LOCAL; CI remoto só antes do hml/tag (piso 27).
2. **Escolha o transporte** (`references/transporte-e-assinatura.md`): webhook/HTTP vs gateway vs polling.
3. **Segredo primeiro** (`references/credenciais-e-token.md`) e **ambientes** (`references/ambientes-e-efeito-externo.md`).
4. **Prazo, fila e limites** (`references/prazo-fila-rate-limit.md`).
5. **Comandos, intents, permissões** (`references/comandos-intents-permissoes.md`).
6. **Entrada hostil e privacidade** (`references/moderacao-entrada-privacidade.md`).

| Tarefa | Reference |
|---|---|
| Token em cofre, rotação, vazou | `references/credenciais-e-token.md` |
| Webhook x gateway x polling; Ed25519, secret_token, signing secret, X-Hub-Signature-256 | `references/transporte-e-assinatura.md` |
| Ack no prazo, fila, rate limit por bucket, 429, dedupe, sharding | `references/prazo-fila-rate-limit.md` |
| Registro de comandos versionado, intents, permissões | `references/comandos-intents-permissoes.md` |
| Moderação, `allowed_mentions`, links, LGPD, LLM | `references/moderacao-entrada-privacidade.md` |
| Servidor/canal de teste, rota nula, cap, fail-closed | `references/ambientes-e-efeito-externo.md` |
| Versões e limites das APIs, com fonte e data (anexo volátil) | `references/stack-versoes.md` |

Assets: `assets/CLAUDE.md` (sempre-on) · `assets/commands/`.

## Pisos inegociáveis (vetam o atalho)

1. **Nunca mensagem real fora de prd** (piso 1 DESTA skill; na base é o piso 18). Bot de teste, servidor/workspace/canal de teste, número de
   teste; ambiente ausente ou desconhecido ⇒ não-prd; só o valor exato de produção fala em canal real;
   token de produção existe só em prd. <!-- herdado:engineering/efeito-externo:invariantes -->**Cap por execução** (`MAIL_MAX_PER_RUN`, default 50) com abort; **fail-closed** (ambiente ausente/desconhecido ⇒ não-prd; só o valor exato de produção entrega de verdade); **chave sandbox** fora de prd. Todo endereço sintético (fixture, seed, persona, demo, carga) é `<papel>+<run-id>-<n>@test.<domain>` — domínio em **rota nula** (null MX RFC 7505 + SPF `-all` + DMARC `p=reject`) ou TLD reservado (`.test`/`.invalid`/`.example`); **VETADO** `@gmail.com`, domínio de cliente/terceiro, e-mail de pessoa real (**inclusive o seu**) e o domínio de produção. A recusa é **erro**, nunca warning nem sucesso silencioso. Entregar de verdade fora de prd exige **as cinco** (ADR + allowlist ≤5 + cap + janela + subdomínio separado). Motivo: bounce/complaint em massa **queima IP e domínio** e derruba o transacional de prd — inclusive o **OTP de login** — com semanas de warm-up e utilidade zero (o incidente dos 5.000 e-mails só existiu porque nada contava).<!-- /herdado -->
2. **Token é segredo.** Em cofre, por ambiente, nunca no repo, imagem, log, URL ou handoff; rotação
   periódica; **vazou ⇒ rotacionar primeiro** (regenerar no portal), depois limpar histórico (`/git-leak`).
3. **Interação por HTTP exige verificação de assinatura antes de tudo**: Discord Ed25519 sobre
   timestamp + corpo bruto, Telegram `secret_token` no `setWebhook`, Slack signing secret com janela de
   replay, WhatsApp `X-Hub-Signature-256`. Falha = `401`, sem corpo útil.
4. **Escolha o transporte por critério**: webhook (serverless, picos, sem estado) x gateway/WebSocket
   (eventos de mensagem, presença, voz) x long polling (dev, atrás de NAT). Nunca dois consumidores do
   mesmo bot no mesmo transporte sem coordenação.
5. **Responda dentro do prazo da plataforma** (ex.: ack de interaction do Discord em 3 s) e processe o
   resto em fila; resposta tardia perde o token da interação.
6. **Respeite rate limit por rota/bucket**: leia os headers, trate `429` com `Retry-After`, backoff
   com jitter, fila de saída; nunca laço de envio sem tratamento de 429 (ban de IP/bot).
7. **Idempotência**: dedupe por `update_id` (Telegram), id da interaction (Discord), `event_id` (Slack),
   id da mensagem (WhatsApp); retry da plataforma é normal.
8. **Intents e permissões mínimas.** Intent privilegiada (`MESSAGE_CONTENT`, `GUILD_MEMBERS`,
   `GUILD_PRESENCES`) só com justificativa registrada no código/ADR; permissão de bot nunca `Administrator`.
9. **Comandos de slash registrados por script versionado**, idempotente (bulk overwrite), com escopo
   de guild em dev e global só em prd.
10. **Entrada do usuário nunca é confiável.** Ao ecoar texto de usuário, `allowed_mentions` restrito
    (nada de `@everyone`/`@here`/cargo), escape de markdown/embeds, links não resolvidos pelo bot sem
    allowlist e SSRF barrado; comando destrutivo exige papel/permissão checados no servidor.
11. **Privacidade (LGPD)**: guarde o mínimo (id, não o conteúdo), retenção curta e declarada, opt-out e
    apagamento atendidos, nada de conteúdo de mensagem em log ou analytics.
12. **Bot com LLM** aponta `schematize-ai`: mensagem do chat é prompt injection em potencial, ferramentas
    mínimas, teto de custo por usuário/guild.
13. **Observável e escalável**: métricas de latência de ack, 429, fila, reconexões; sharding quando a
    plataforma exigir (Discord a partir de 2.500 guilds); reconexão do gateway com resume.
14. <!-- herdado:engineering/orquestracao:curto -->**Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para o executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código; falhou → mesmo subagent corrige, até 2 rodadas) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo) → `park`; **visual vai direto ao Codex**; **imagem nunca pelo Claude: detectar Codex/Gemini e perguntar ao usuário qual usar (Codex é a sugestão), nunca API de imagem paga**; papéis em `agentes.toml`. No overdev, cada item do checklist vai a um subagent e o principal revisa antes do `- [x]`. **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata (§9.6). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.<!-- /herdado -->

## Regra de mídia

Esta skill não gera visual. Se o trabalho tocar avatar, banner ou embed com imagem, a mídia gerada
**nunca** vem de modelo Claude: detecte Codex e Gemini disponíveis e **pergunte ao usuário qual
usar**. Nenhum disponível: avise sem rodeio que visual gerado pelo Claude tem qualidade
inversamente proporcional à de código (sai ruim de verdade) e ofereça alternativas — instalar Codex
ou Gemini, imagem de banco com licença comercial, ou asset do cliente.

## Relação com as outras skills

- **`schematize-engineering`** — a base: DoD, archive, IAM, efeito externo, ambientes.
- **`schematize-api`** · **`schematize-ai`** · **`schematize-iam`** · **`schematize-payments`** — divisas acima.
- **`schematize-infra`** · **`schematize-docker`** · **`schematize-observability`** — deploy, imagem, métricas.
- **`schematize-git`** · **`schematize-incident`** — token vazado e resposta.

<!-- herdado:engineering/pisos-22-29:bloco -->**Herda os pisos 22–29 da `schematize-engineering`** (texto completo em `assets/CLAUDE.md` dela): 22 tudo no git — sem remote, push falho ou HEAD≠origin a demanda NÃO se conclui; 23 deploy só do git (VETADO scp/rsync/tar|ssh/docker save|load/git bundle); 24 o ops é o gate da IA — a IA nunca muda a VPS direto nem escreve SQL, só operação nomeada (`ssh vps "ops <op>"`); 25 sem agents inúteis (entregou, morreu); 26 relatório a cada 30 min e handoff a cada 6 h; 27 CI remoto só antes do hml, a pedido ou em tag (`workflow_dispatch` + `hml-*`/`v*`; VETADO `pull_request`, `push` em branch, `workflow_run`, cron sem justificativa); 28 microserviço autônomo (fila durável + 7 testes de resiliência); 29 build/teste na máquina dev/hml quando existe (ponte só no workspace de build, nunca prd) + higiene (`scripts/higiene.sh`).<!-- /herdado -->
