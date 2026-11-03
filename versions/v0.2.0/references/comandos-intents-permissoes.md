# Comandos, intents e permissões

> Parte da skill **schematize-bots**.

## 1. Slash commands como contrato versionado
- Manifesto no repo (nome, descrição, opções, `default_member_permissions`, contexts) + script de
  registro idempotente (Discord: *bulk overwrite*; Telegram: `setMyCommands`; Slack: manifesto do app).
- Dev: escopo de guild/workspace de teste (propaga na hora). Prd: global. Registro roda no deploy, não no boot.
- Mudança incompatível = versão nova no manifesto + CHANGELOG.

## 2. Intents (Discord gateway)
Privilegiadas: `GUILD_MEMBERS`, `GUILD_PRESENCES`, `MESSAGE_CONTENT`. Habilitar no portal e só pedir no IDENTIFY o que usa.
Bots em 100+ guilds precisam de verificação e aprovação para as privilegiadas. Interactions (slash,
botões, modais) não precisam de `MESSAGE_CONTENT`: prefira-as a prefixo de texto.
Justificativa no código, ao lado do uso: `// bot-intent-ok: <motivo>` (ver gate).

## 3. Permissões
Convite com o conjunto mínimo; nunca `Administrator`; separe papéis do bot por função; Telegram: modo
de privacidade do bot ligado (só vê comandos e menções) salvo necessidade; Slack: escopos mínimos (`chat:write`, não `admin`).
Comando destrutivo checa papel/permissão do **usuário** no servidor.
