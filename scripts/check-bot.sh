#!/usr/bin/env bash
# check-bot.sh — gate estático do piso de bots de chat da schematize-bots.
#
# Motivo: token commitado, webhook sem assinatura, eco de entrada de usuário sem allowed_mentions,
# laço de envio sem tratamento de 429, intent privilegiada sem justificativa e setWebhook sem
# secret_token são os defeitos recorrentes de bot. Este gate os pega por varredura de texto, sem
# depender de linguagem ou SDK.
# Como funciona: percorre o repo (ignora .git, node_modules, vendor, target, _build, deps, dist),
# aplica as regras e imprime `arquivo:linha: [regra] mensagem`. Waiver rastreável, na linha ou na
# de cima: `bot-ok: <motivo>` (motivo obrigatório); regras de arquivo inteiro: `bot-ok: <regra> <motivo>`.
# Intent privilegiada: justificativa `bot-intent-ok: <motivo>` na linha ou até 2 linhas acima.
# Regras: bot-token-literal · bot-webhook-sem-assinatura · bot-telegram-sem-secret-token ·
#   bot-eco-sem-allowed-mentions · bot-envio-sem-429 · bot-intent-sem-justificativa
# Entrada: $1 = diretório do repo (default: .).
# Saída: 0 passa · 1 reprova · 2 nada para verificar (que NÃO é aprovação).
set -euo pipefail

raiz="${1:-.}"
[ -d "$raiz" ] || { echo "check-bot: diretório inexistente: $raiz" >&2; exit 2; }

CODE_RE='\.(go|rs|ex|exs|cs|rb|py|ts|tsx|js|jsx|mjs|cjs|php|java|kt|swift|dart|zig)$'
TEST_RE='(^|/)(test|tests|spec|specs|__tests__|e2e|fixtures)(/|$)|(_test|\.test|\.spec|_spec)\.[a-z]+$'

mapfile -d '' arquivos < <(find "$raiz" \( -name .git -o -name node_modules -o -name vendor -o -name target \
  -o -name _build -o -name deps -o -name dist -o -name .next \) -prune -o -type f -print0 | sort -z)

achados=0
verificados=0

achado() {
  local f="$1" n="$2" regra="$3" msg="$4"
  if [ "$n" -gt 0 ]; then
    if sed -n "${n}p" "$f" | grep -qE 'bot-ok:[[:space:]]*[^[:space:]]'; then return 0; fi
    if [ "$n" -gt 1 ] && sed -n "$((n - 1))p" "$f" | grep -qE 'bot-ok:[[:space:]]*[^[:space:]]'; then return 0; fi
  else
    if grep -qE "bot-ok:[[:space:]]*${regra}[[:space:]]+[^[:space:]]" "$f"; then return 0; fi
  fi
  echo "${f}:${n}: [${regra}] ${msg}"
  achados=$((achados + 1))
}

por_linha() {
  local f="$1" re="$2" regra="$3" msg="$4" n
  while IFS=: read -r n _; do
    [ -n "$n" ] || continue
    achado "$f" "$n" "$regra" "$msg"
  done < <(grep -nIE -e "$re" "$f" 2>/dev/null || true)
}

# código sem comentários (linha inteira e cauda), preservando a numeração: comentário NÃO prova verificação
limpo() { sed -E 's/^[[:space:]]*(\/\/|#|--|\*|\/\*).*$//; s/[[:space:]](\/\/|#)[[:space:]].*$//' "$1"; }

# primeira linha que casa (ou 0)
primeira() { grep -nIiE -e "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 || true; }

TOKEN_RE='[A-Za-z][A-Za-z0-9_-]{23,25}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}|\b[0-9]{8,10}:[A-Za-z0-9_-]{35}\b|xox[abposr]-[0-9A-Za-z-]{10,}|xapp-[0-9]-[A-Z0-9]+-[0-9]+-[0-9a-f]{20,}|xoxe(\.xox[bp])?-[0-9]-[A-Za-z0-9-]{20,}|\bEAA[A-Za-z0-9]{20,}\b|\bsyt_[A-Za-z0-9_-]{16,}'
VERIFICA_RE='(verify_?key|verifyKey|verify_?signature|ed25519|X-Signature-Ed25519|secret_token|X-Telegram-Bot-Api-Secret-Token|X-Slack-Signature|signing_?secret|X-Hub-Signature-256|x-hub-signature|hs_token|timingSafeEqual|compare_digest|ConstantTimeCompare|secure_compare|hmac)'
ENVIO_RE='(channel\.send|\.sendMessage|send_message|chat\.postMessage|chat_postMessage|messages\.create|bot\.send|\.send_text|createMessage|create_message|(user|member|dm|author|interaction\.followup|followup)\.send|\.reply|\.followUp)\('
LACO_RE='(^|[^A-Za-z_])(for|while)[[:space:](]|\.forEach\(|for_each|\.each[[:space:]({]|\.map\(|asyncio\.gather|Promise\.all'
TRATA429_RE='(429|retry[_-]?after|rate[_-]?limit|ratelimit|RateLimit|retryAfter|FloodWait|too many requests)'
INTENT_RE='(MESSAGE_CONTENT|message_content|MessageContent|GUILD_MEMBERS|GuildMembers|GUILD_PRESENCES|GuildPresences|intents\.(members|presences)|privileged_intents)'

for f in "${arquivos[@]}"; do
  rel="${f#"$raiz"/}"
  grep -qI . "$f" 2>/dev/null || continue
  case "$rel" in *.lock|*package-lock.json|*.sum|*.min.js) continue ;; esac
  verificados=$((verificados + 1))

  # --- token literal (qualquer arquivo de texto)
  por_linha "$f" "$TOKEN_RE" bot-token-literal \
    'token de bot literal no repositório: rotacione agora (regenere no portal), leia de um cofre e limpe o histórico (/git-leak)'

  codigo=0; [[ "$rel" =~ $CODE_RE ]] && codigo=1
  [ "$codigo" = 1 ] || continue

  # --- intent privilegiada sem justificativa (inclusive em teste: o piso vale igual)
  while IFS=: read -r n resto; do
    [ -n "$n" ] || continue
    printf '%s' "$resto" | grep -qiE '(=|:)[[:space:]]*(false|False)\b' && continue
    janela="$(sed -n "$((n > 2 ? n - 2 : 1)),${n}p" "$f")"
    printf '%s' "$janela" | grep -qE 'bot-intent-ok:[[:space:]]*[^[:space:]]' && continue
    achado "$f" "$n" bot-intent-sem-justificativa \
      'intent privilegiada sem justificativa: marque `bot-intent-ok: <motivo>` na linha ou até 2 acima (interactions dispensam MESSAGE_CONTENT)'
  done < <(grep -nIE -e "$INTENT_RE" "$f" 2>/dev/null || true)

  [[ "$rel" =~ $TEST_RE ]] && continue

  # --- setWebhook do Telegram sem secret_token
  if grep -qiE 'setWebhook|set_webhook' "$f" && ! limpo "$f" | grep -qiE 'secret_token'; then
    n="$(primeira "$f" 'setWebhook|set_webhook')"
    achado "$f" "${n:-0}" bot-telegram-sem-secret-token \
      'setWebhook sem secret_token: qualquer um pode forjar updates no seu endpoint'
  fi

  # --- handler de webhook/interactions sem verificação de assinatura
  if grep -qiE '(discord|telegram|slack|whatsapp|matrix|interaction)' "$f" \
     && grep -qiE '["/](interactions|webhook|webhooks|slack/events|telegram|whatsapp)["/ ]?' "$f" \
     && grep -qiE '(post|route|router|handler|controller|endpoint|@app\.|app\.(post|put)|def |func |fn |function |async )' "$f"; then
    if ! limpo "$f" | grep -qiE "$VERIFICA_RE"; then
      n="$(primeira "$f" '["/](interactions|webhook|webhooks|slack/events|telegram|whatsapp)')"
      achado "$f" 0 bot-webhook-sem-assinatura \
        "handler de webhook/interactions de bot sem verificação de assinatura (Ed25519, secret_token, signing secret ou X-Hub-Signature-256), linha ${n:-?}"
    fi
  fi

  # --- eco de entrada de usuário sem allowed_mentions (Discord)
  if grep -qiE 'discord' "$f" && ! grep -qiE '(allowed_?mentions|AllowedMentions|parse:[[:space:]]*\[\])' "$f"; then
    while IFS=: read -r n _; do
      [ -n "$n" ] || continue
      achado "$f" "$n" bot-eco-sem-allowed-mentions \
        'entrada de usuário ecoada sem allowed_mentions: `@everyone`/`@here` digitado pelo usuário vira spam em massa'
    done < <(grep -nIiE '(send|reply|followup|create_message|say|respond)[A-Za-z_]*\(.*(message\.content|msg\.content|\.options\.(get|data)|getString\(|user_?input|args\[|\$\{[^}]*(input|text|content|args|query)[^}]*\})' "$f" 2>/dev/null || true)
  fi

  # --- laço de envio sem tratamento de 429
  if ! limpo "$f" | grep -qiE "$TRATA429_RE"; then
    while IFS=: read -r n _; do
      [ -n "$n" ] || continue
      ini=$((n > 8 ? n - 8 : 1))
      if sed -n "${ini},${n}p" "$f" | grep -qE "$LACO_RE"; then
        achado "$f" "$n" bot-envio-sem-429 \
          'envio em laço sem tratamento de 429/Retry-After: respeite o bucket, faça backoff com jitter (ou waiver bot-ok: o SDK já limita)'
      fi
    done < <(grep -nIE -e "$ENVIO_RE" "$f" 2>/dev/null || true)
  fi
done

if [ "$verificados" -eq 0 ]; then
  echo "check-bot: nenhum arquivo de texto para verificar em $raiz (exit 2: isto NÃO é aprovação)" >&2
  exit 2
fi
# piso 18 (efeito externo): o gate principal também roda check-bot-effects.sh (mesmo diretório),
# para que quem roda só este gate pegue o efeito externo. rc 2 do auxiliar (nada a verificar) não reprova.
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$AQUI/check-bot-effects.sh" ]; then
  rc_ef=0
  bash "$AQUI/check-bot-effects.sh" "$raiz" || rc_ef=$?
  [ "$rc_ef" -eq 0 ] || [ "$rc_ef" -eq 2 ] || achados=$((achados + 1))
fi
if [ "$achados" -gt 0 ]; then
  echo "check-bot: $achados achado(s) em $verificados arquivo(s)" >&2
  exit 1
fi
echo "check-bot: ok ($verificados arquivo(s) verificados)"
echo "check-bot: o gate é estático; ele não prova ack no prazo, dedupe nem privacidade (veja /bot-review)" >&2
