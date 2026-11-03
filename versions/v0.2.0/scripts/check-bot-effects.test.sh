#!/usr/bin/env bash
# Vermelho->verde do gate check-bot-effects.sh (bots, piso 18).
# EXCEÇÃO DECLARADA (schematize-shell): harness `set -u` sem `-e` para reportar todos os casos.
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-bot-effects.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT INT TERM
ok=0; fail=0; D=""; NOME=""
novo() { D="$TMP/$1"; mkdir -p "$D"; NOME="$1"; }
f() { mkdir -p "$(dirname "$D/$1")"; cat >"$D/$1"; }
esperar() {
  local esp="$1" agulha="$2" saida rc
  saida="$(bash "$G" "$D" 2>&1)"; rc=$?
  if [ "$rc" != "$esp" ]; then echo "  ✖ $NOME: exit $rc, esperado $esp"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  if [ -n "$agulha" ] && ! grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $NOME: saída sem \"$agulha\""; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $NOME"; ok=$((ok+1))
}
echo "== gate external-effects (bot) =="

novo vazio; mkdir -p "$D"; esperar 2 "nenhum arquivo"

PROVIDER_OK='import os
class SinkProvider:
    def send(self, dest, text): print("sink", dest)
class OutboundGuard:
    def __init__(self):
        self.env = os.environ.get("BOT_ENV", "dev")
        self.cap = int(os.environ.get("BOT_MAX_MSGS_PER_RUN", "20"))
        self.allow = os.environ.get("BOT_TEST_ALLOWLIST", "").split(",")
        self.enviadas = 0
    def provider(self):
        return RealProvider(self) if self.env == "prd" else SinkProvider()
class RealProvider:
    def __init__(self, g): self.g = g
    def post(self, ch, text):
        if self.g.env != "prd" and ch not in self.g.allow: raise PermissionError("fora de prd")
        if self.g.enviadas >= self.g.cap: raise RuntimeError("cap")
        ch.send(text)
'
novo verde-provider-com-guard
printf '%s' "$PROVIDER_OK" | f src/provider.py
esperar 0 "ok ("

novo vermelho-envio-direto-sem-guard
f src/handler.py <<'FIX'
async def on_msg(channel, text):
    await channel.send(text)
FIX
esperar 1 "bot-envio-sem-guard"

novo vermelho-guard-so-em-comentario
f src/provider.py <<'FIX'
# if env == "prd" and BOT_TEST_ALLOWLIST and BOT_MAX_MSGS_PER_RUN
class Sink: pass
def go(ch): ch.send("x")
FIX
esperar 1 "bot-envio-sem-guard"

novo vermelho-default-prd
printf '%s' "$PROVIDER_OK" | sed 's/"BOT_ENV", "dev"/"BOT_ENV", "production"/' | f src/provider.py
esperar 1 "bot-default-prd"

novo vermelho-lista-negra
printf '%s\n' "$PROVIDER_OK" 'def x(env, ch):' '    if env != "dev": ch.send("a")' | f src/provider.py
esperar 1 "bot-guard-nao-fail-closed"

novo vermelho-sem-sink
f src/provider.py <<'FIX'
import os
ENV = os.environ.get("BOT_ENV")
CAP = os.environ.get("BOT_MAX_MSGS_PER_RUN")
ALLOW = os.environ.get("BOT_TEST_ALLOWLIST")
def send(ch):
    if ENV == "prd": ch.send("x")
FIX
esperar 1 "bot-sem-sink"

novo vermelho-token-prd-em-env-dev
f .env.dev <<'FIX'
BOT_TOKEN_PRD=abc
FIX
esperar 1 "bot-prd-em-nao-prd"

novo vermelho-token-prd-waiver-nao-vale
f config/dev.yaml <<'FIX'
# bot-ok: preciso
DISCORD_TOKEN_PROD: abc
FIX
esperar 1 "bot-prd-em-nao-prd"

novo verde-token-prd-em-env-prd
f .env.prd <<'FIX'
BOT_TOKEN_PRD=abc
FIX
esperar 0 "ok ("

novo verde-waiver
printf '%s\n' "$PROVIDER_OK" 'def y(ch):' '    ch.send("a")  # bot-ok: so teste manual local' | f src/provider.py
esperar 0 "ok ("

echo "== $ok ok, $fail falha(s) =="
[ "$fail" -eq 0 ]
