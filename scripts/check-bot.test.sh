#!/usr/bin/env bash
# Vermelho primeiro do gate check-bot.sh. Cada fixture é um mini-repo com UM defeito (vermelho)
# ou um uso correto parecido (verde plantado, que NÃO pode ser acusado).
# Segredos falsos são MONTADOS em tempo de execução (push protection do GitHub bloqueia literais).
#
# EXCEÇÃO DECLARADA (piso da schematize-shell, strict mode): harness de teste roda `set -u` sem `-e`
# — precisa continuar depois de um caso vermelho para reportar todos, em vez de parar no primeiro.
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-bot.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT INT TERM
ok=0; fail=0
D=""; NOME=""

A24="$(printf 'A%.0s' $(seq 1 24))"   # 24 caracteres
B27="$(printf 'b%.0s' $(seq 1 27))"
C35="$(printf 'c%.0s' $(seq 1 35))"
DISCORD_FALSO="M${A24}.abcdef.${B27}"
TELEGRAM_FALSO="1234567890:${C35}"
WA_FALSO="$(printf 'w%.0s' $(seq 1 30))"
SLACK_FALSO="xo""xb-1234567890-abcdefghij"

novo() { D="$TMP/$1"; mkdir -p "$D"; NOME="$1"; }
f() {
  mkdir -p "$(dirname "$D/$1")"
  sed "s/@@DISCORD@@/$DISCORD_FALSO/g; s/@@TELEGRAM@@/$TELEGRAM_FALSO/g; s/@@SLACK@@/$SLACK_FALSO/g; s/@@WA@@/$WA_FALSO/g; s/@@DA@@/$A24/g; s/@@DB@@/$B27/g" >"$D/$1"
}
esperar() {
  local esp="$1" agulha="$2" saida rc
  saida="$(bash "$G" "$D" 2>&1)"; rc=$?
  if [ "$rc" != "$esp" ]; then echo "  ✖ $NOME: exit $rc, esperado $esp"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  if [ -n "$agulha" ] && ! grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $NOME: exit certo, saída sem \"$agulha\""; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $NOME"; ok=$((ok+1))
}
esperar_sem() {
  local agulha="$1" saida
  saida="$(bash "$G" "$D" 2>&1)"
  if grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $NOME: acusou \"$agulha\" indevidamente"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $NOME"; ok=$((ok+1))
}

echo "== gate bot =="

novo vazio; mkdir -p "$D"
esperar 2 "nenhum arquivo"
novo dir-inexistente; D="$TMP/nao-existe"
esperar 2 "inexistente"

# ---------------- bot-token-literal
novo token-discord
f src/bot.js <<'FIX'
client.login("@@DISCORD@@");
FIX
esperar 1 "bot-token-literal"
novo token-telegram
f config.yaml <<'FIX'
bot_token: "@@TELEGRAM@@"
FIX
esperar 1 "bot-token-literal"
novo token-slack
f .env.example <<'FIX'
SLACK_BOT_TOKEN=@@SLACK@@
FIX
esperar 1 "bot-token-literal"
novo token-do-cofre-verde
f src/bot.js <<'FIX'
client.login(process.env.DISCORD_TOKEN);
const hora = "12:30:45"; const ratio = "1234567890:abc";
FIX
esperar_sem "bot-token-literal"
novo token-waiver-verde
f docs/exemplo.md <<'FIX'
<!-- bot-ok: exemplo didático, token inválido -->
token = "@@TELEGRAM@@"
FIX
esperar_sem "bot-token-literal"

# ---------------- bot-webhook-sem-assinatura
novo webhook-sem-assinatura
f src/server.ts <<'FIX'
app.post("/interactions", async (req, res) => {
  const body = req.body; // discord
  if (body.type === 1) return res.json({ type: 1 });
  res.json({ type: 5 });
});
FIX
esperar 1 "bot-webhook-sem-assinatura"
novo webhook-com-assinatura-verde
f src/server.ts <<'FIX'
import { verifyKey } from "discord-interactions";
app.post("/interactions", async (req, res) => {
  const ok = await verifyKey(req.rawBody, req.header("X-Signature-Ed25519"), req.header("X-Signature-Timestamp"), process.env.DISCORD_PUBLIC_KEY);
  if (!ok) return res.status(401).end();
  res.json({ type: 5 });
});
FIX
esperar_sem "bot-webhook-sem-assinatura"
novo slack-com-hmac-verde
f src/slack.py <<'FIX'
# slack events
@app.post("/slack/events")
def events():
    esperado = "v0=" + hmac.new(SIGNING_SECRET, f"v0:{ts}:{raw}".encode(), "sha256").hexdigest()
    if not hmac.compare_digest(esperado, request.headers["X-Slack-Signature"]):
        abort(401)
FIX
esperar_sem "bot-webhook-sem-assinatura"
novo webhook-em-teste-verde
f tests/server.test.ts <<'FIX'
// discord
await post("/interactions", {});
FIX
esperar_sem "bot-webhook-sem-assinatura"

# ---------------- bot-telegram-sem-secret-token
novo setwebhook-sem-secret
f scripts/registrar.py <<'FIX'
requests.post(f"https://api.telegram.org/bot{TOKEN}/setWebhook", json={"url": URL})
FIX
esperar 1 "bot-telegram-sem-secret-token"
novo setwebhook-com-secret-verde
f scripts/registrar.py <<'FIX'
requests.post(f"https://api.telegram.org/bot{TOKEN}/setWebhook", json={"url": URL, "secret_token": SEGREDO})
FIX
esperar_sem "bot-telegram-sem-secret-token"

# ---------------- bot-eco-sem-allowed-mentions
novo eco-sem-allowed-mentions
f src/cmd.js <<'FIX'
const { Client } = require("discord.js");
client.on("messageCreate", (message) => {
  message.channel.send(`Você disse: ${message.content}`);
});
FIX
esperar 1 "bot-eco-sem-allowed-mentions"
novo eco-slash-sem-allowed-mentions
f src/cmd.py <<'FIX'
import discord
async def eco(interaction, texto: str):
    await interaction.response.send_message(f"{interaction.options.get('texto')}")
FIX
esperar 1 "bot-eco-sem-allowed-mentions"
novo eco-com-allowed-mentions-verde
f src/cmd.js <<'FIX'
const { Client } = require("discord.js");
client.on("messageCreate", (message) => {
  message.channel.send({ content: `Você disse: ${message.content}`, allowedMentions: { parse: [] } });
});
FIX
esperar_sem "bot-eco-sem-allowed-mentions"
novo mensagem-fixa-verde
f src/cmd.js <<'FIX'
const { Client } = require("discord.js");
client.on("messageCreate", (message) => { message.channel.send("pong"); });
FIX
esperar_sem "bot-eco-sem-allowed-mentions"

# ---------------- bot-envio-sem-429
novo laco-sem-429
f src/difusao.py <<'FIX'
def difundir(bot, chats, texto):
    for chat in chats:
        bot.send_message(chat, texto)
FIX
esperar 1 "bot-envio-sem-429"
novo laco-com-429-verde
f src/difusao.py <<'FIX'
def difundir(bot, chats, texto):
    for chat in chats:
        r = bot.send_message(chat, texto)
        if r.status == 429:
            time.sleep(r.headers["Retry-After"])
FIX
esperar_sem "bot-envio-sem-429"
novo envio-unico-verde
f src/aviso.py <<'FIX'
def avisar(bot, chat):
    bot.send_message(chat, "oi")
FIX
esperar_sem "bot-envio-sem-429"
novo laco-waiver-verde
f src/difusao.py <<'FIX'
def difundir(bot, chats, texto):
    for chat in chats:
        # bot-ok: a lib aiogram aplica o limiter por chat
        bot.send_message(chat, texto)
FIX
esperar_sem "bot-envio-sem-429"

# ---------------- bot-intent-sem-justificativa
novo intent-sem-justificativa
f src/main.py <<'FIX'
intents = discord.Intents.default()
intents.message_content = True
FIX
esperar 1 "bot-intent-sem-justificativa"
novo intent-js-sem-justificativa
f src/index.js <<'FIX'
const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.MessageContent] });
FIX
esperar 1 "bot-intent-sem-justificativa"
novo intent-justificada-verde
f src/main.py <<'FIX'
intents = discord.Intents.default()
# bot-intent-ok: moderação por palavra-chave exige o texto; ADR-0007
intents.message_content = True
FIX
esperar_sem "bot-intent-sem-justificativa"
novo intent-desligada-verde
f src/main.py <<'FIX'
intents.message_content = False
FIX
esperar_sem "bot-intent-sem-justificativa"

# ---------------- verde completo
novo verde-completo
f src/server.ts <<'FIX'
import { verifyKey } from "discord-interactions";
app.post("/interactions", async (req, res) => {
  if (!(await verifyKey(req.rawBody, req.header("X-Signature-Ed25519"), req.header("X-Signature-Timestamp"), process.env.DISCORD_PUBLIC_KEY))) return res.status(401).end();
  res.json({ type: 5 });
});
FIX
f src/envio.ts <<'FIX'
// discord
async function enviar(canal, msgs) {
  for (const m of msgs) {
    const r = await canal.send({ content: m, allowedMentions: { parse: [] } });
    if (r.status === 429) await dormir(r.headers["retry-after"]);
  }
}
FIX
esperar 0 "check-bot: ok"

# ---------------- falsos verdes corrigidos (G8b)
novo webhook-hmac-so-em-comentario
f src/server.py <<'FIX'
# discord interactions
@app.post("/interactions")
def inter():
    # TODO hmac later
    return handle(request.json)
FIX
esperar 1 "bot-webhook-sem-assinatura"
novo dm-em-laco-user-send-v
f src/dm.js <<'FIX'
// discord
for (const user of users) { await user.send("x"); }
FIX
esperar 1 "bot-envio-sem-429"
novo token-whatsapp-eaa
f config.yaml <<'FIX'
wa_token: "EAA@@WA@@"
FIX
esperar 1 "bot-token-literal"
novo token-matrix-syt
f config.yaml <<'FIX'
matrix_token: "syt_@@WA@@"
FIX
esperar 1 "bot-token-literal"
novo token-discord-prefixo-livre
f config.yaml <<'FIX'
t: "Z@@DA@@.abcdef.@@DB@@"
FIX
esperar 1 "bot-token-literal"

echo "== resultado: $ok ok, $fail falhas =="
[ "$fail" -eq 0 ]
