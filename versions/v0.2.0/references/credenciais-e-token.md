# Credenciais e token

> Parte da skill **schematize-bots**.

## 1. O que é segredo
Token do bot (Discord bot token, Telegram `123456:ABC...` do BotFather, Slack `xoxb-`/`xapp-`/`xoxp-`),
signing secret, client secret OAuth, app secret da Meta, access token do WhatsApp, access token Matrix.
A **chave pública** do app Discord (verificação Ed25519) não é segredo, mas fica em configuração por ambiente.

## 2. Onde mora
- Cofre por ambiente (`schematize-infra → /infra-secrets`); entra no processo por variável de ambiente
  ou arquivo montado, nunca em imagem (`schematize-docker`), nunca em argumento de linha de comando.
- **Um token por ambiente**: dev, teste e prd são bots (aplicações) diferentes. O token de prd não
  existe fora de prd.
- Log: redija o token; erro de SDK que imprime a configuração é incidente. URL da API do Telegram
  carrega o token no caminho (`/bot<token>/`): nunca logue a URL completa.

## 3. Rotação
Periódica e sob demanda; o processo aceita recarregar o segredo sem derrubar a fila. Discord: regenerar
no Developer Portal invalida o anterior. Telegram: `/revoke` no BotFather. Slack: rotacionar tokens e
signing secret no painel do app.

## 4. Vazou
**Rotacione primeiro** (regenerar invalida de imediato), depois confira os logs de uso (mensagens que o
bot não enviou, convites, comandos), depois limpe o histórico (`schematize-git → /git-leak`,
`references/segredos.md`). Incidente em massa (spam disparado): `schematize-incident`.
Scanners públicos revogam alguns tokens sozinhos; não conte com isso.
