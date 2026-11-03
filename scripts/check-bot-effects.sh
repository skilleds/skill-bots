#!/usr/bin/env bash
# check-bot-effects.sh — gate do piso 18 da schematize-engineering ("efeito externo NUNCA sai
# de não-produção") aplicado a BOTS: prova por varredura que o envio real tem sink por default,
# guard DENTRO do provider (fail-closed por env e por destinatário), cap por execução e que
# nenhuma credencial de prd vive em arquivo de ambiente não-prd.
# (O piso 1 DESTA skill é outro: token em cofre. O piso de efeito externo é o 18 da base.)
#
# Regras (um achado por arquivo/linha, `arquivo:linha: [regra] msg`):
#   bot-default-prd           ambiente com default de produção (ausente deve cair no sink)
#   bot-guard-nao-fail-closed guard por lista negra de ambientes (`env != "dev"`): só "prd" EXATO libera
#   bot-envio-sem-guard       arquivo de produção que envia (send/post/reply/DM) sem, NO MESMO arquivo:
#                               (a) comparação exata com prd, (b) allowlist de destinatário de teste
#                               (BOT_TEST_ALLOWLIST), (c) cap por execução (BOT_MAX_MSGS_PER_RUN)
#   bot-sem-sink              há envio real no repo e nenhum sink/dry-run (provider default)
#   bot-prd-em-nao-prd        credencial/token de prd em arquivo de ambiente não-prd
# Comentários NÃO contam como guard (são removidos antes de casar).
# Waiver rastreável, na linha ou na de cima: `bot-ok: <motivo>` (não vale para bot-prd-em-nao-prd).
# Entrada: $1 = diretório (default .). Saída: 0 passa · 1 reprova · 2 nada a verificar.
set -euo pipefail

raiz="${1:-.}"
[ -d "$raiz" ] || { echo "check-bot-effects: diretório inexistente: $raiz" >&2; exit 2; }

CODE_RE='\.(go|rs|ex|exs|cs|rb|py|ts|tsx|js|jsx|mjs|cjs|php|java|kt|swift|dart|zig)$'
CONF_RE='(\.(env|ya?ml|toml|json|tf|tfvars|properties|conf|ini)$|(^|/)\.env[^/]*$)'
TEST_RE='(^|/)(test|tests|spec|specs|__tests__|e2e|fixtures)(/|$)|(_test|\.test|\.spec|_spec)\.[a-z]+$'
NAO_PRD_RE='(^|/|[._-])(dev|development|hml|homolog|homologacao|stg|staging|test|tests|sandbox|local|e2e|qa)([._/-]|$)'
PRD_RE='(^|/|[._-])(prd|prod|production)([._/-]|$)'
ENVIO_RE='(\.send\(|channel\.send|\.sendMessage|send_message|chat\.postMessage|chat_postMessage|messages\.create|bot\.send|\.send_text|createMessage|create_message|followup\.send|\.reply\(|sendText|SendMessage|send_dm|dm\.send)'
PRD_CMP='((==|===|=~|!=|!==)[[:space:]]*["'"'"'](prd|prod|production)["'"'"']|["'"'"'](prd|prod|production)["'"'"'][[:space:]]*(==|===|!=|!==)|(equals|eq\?|\.eq|isEqual|is_prd|isProd|is_production)[^;]{0,40}["'"'"'](prd|prod|production)["'"'"'])'
SINK_RE='(Sink|sink|DryRun|dry_run|dry-run|NullClient|NoopClient|FakeClient|LogOnly)'
ALLOW_RE='(BOT_TEST_ALLOWLIST|TEST_ALLOWLIST|test_allowlist|allowlist_teste|RECIPIENT_ALLOWLIST)'
CAP_RE='(BOT_MAX_MSGS_PER_RUN|MAX_MSGS_PER_RUN|max_msgs_per_run|MAX_MESSAGES_PER_RUN)'

mapfile -d '' arquivos < <(find "$raiz" \( -name .git -o -name node_modules -o -name vendor -o -name target \
  -o -name _build -o -name deps -o -name dist -o -name .next \) -prune -o -type f -print0 | sort -z)

achados=0; verificados=0; envio_real=0; tem_sink=0

achado() {
  local f="$1" n="$2" regra="$3" msg="$4"
  if [ "$regra" != bot-prd-em-nao-prd ]; then
    if [ "$n" -gt 0 ]; then
      sed -n "${n}p" "$f" | grep -qE 'bot-ok:[[:space:]]*[^[:space:]]' && return 0
      if [ "$n" -gt 1 ]; then sed -n "$((n - 1))p" "$f" | grep -qE 'bot-ok:[[:space:]]*[^[:space:]]' && return 0; fi
    else
      grep -qE "bot-ok:[[:space:]]*${regra}[[:space:]]+[^[:space:]]" "$f" && return 0
    fi
  fi
  echo "${f}:${n}: [${regra}] ${msg}"
  achados=$((achados + 1))
}

# código sem comentários (linha inteira e cauda ` // ...` / ` # ...`), preservando números de linha
limpo() { sed -E 's/^[[:space:]]*(\/\/|#|--|\*|\/\*).*$//; s/[[:space:]](\/\/|#)[[:space:]].*$//' "$1"; }

for f in "${arquivos[@]}"; do
  rel="${f#"$raiz"/}"
  grep -qI . "$f" 2>/dev/null || continue
  case "$rel" in *.lock|*package-lock.json|*.sum|*.min.js) continue ;; esac
  codigo=0; conf=0
  [[ "$rel" =~ $CODE_RE ]] && codigo=1
  [[ "$rel" =~ $CONF_RE ]] && conf=1
  [ "$codigo" = 1 ] || [ "$conf" = 1 ] || continue
  verificados=$((verificados + 1))

  # --- credencial de prd em arquivo de ambiente não-prd (sem waiver)
  if [ "$conf" = 1 ] && [[ "$rel" =~ $NAO_PRD_RE ]] && ! [[ "$rel" =~ $PRD_RE ]]; then
    while IFS=: read -r n _; do
      [ -n "$n" ] || continue
      achado "$f" "$n" bot-prd-em-nao-prd 'credencial de bot de PRODUÇÃO em arquivo de ambiente não-prd: fora de prd só o bot/token de TESTE (workspace/servidor de teste)'
    done < <(limpo "$f" | grep -nIiE '(_(PRD|PROD|PRODUCTION|LIVE)[A-Z_]*(TOKEN|SECRET|KEY)|(TOKEN|SECRET|KEY)[A-Z_]*_(PRD|PROD|PRODUCTION|LIVE))[[:space:]]*[=:]' || true)
  fi

  [ "$codigo" = 1 ] || continue
  [[ "$rel" =~ $TEST_RE ]] && continue
  tmp="$(mktemp)"; limpo "$f" >"$tmp"

  # --- default prd
  while IFS=: read -r n _; do
    [ -n "$n" ] || continue
    achado "$f" "$n" bot-default-prd 'ambiente com default de PRODUÇÃO: ausente/desconhecido deve cair no SINK (fail-closed); só o valor exato de prd envia de verdade'
  done < <(grep -nIE "(APP_ENV|BOT_ENV|ENVIRONMENT|NODE_ENV|RAILS_ENV|MIX_ENV|[Ee]nv(ironment)?)[^#]{0,60}(\|\||\?\?|unwrap_or(_else)?\(|:-|, *|\bor |default[:=] *)[[:space:]]*[\"']?(production|prod|prd)[\"']" "$tmp" || true)

  # --- guard por lista negra (não fail-closed)
  while IFS=: read -r n _; do
    [ -n "$n" ] || continue
    achado "$f" "$n" bot-guard-nao-fail-closed 'guard por lista negra de ambientes: ambiente novo/typo vira envio real; inverta (só "prd" exato envia, o resto é sink)'
  done < <(grep -nIiE "(env|environment)[A-Za-z_.()]*[[:space:]]*(!=|!==|is not|not in)[[:space:]]*[\"'](dev|development|test|hml|staging|local|sandbox)[\"']" "$tmp" || true)

  # --- sink presente?
  grep -qE "$SINK_RE" "$tmp" && tem_sink=1

  # --- envio real sem guard no mesmo arquivo
  if grep -qE "$ENVIO_RE" "$tmp"; then
    envio_real=1
    faltam=""
    grep -qE "$PRD_CMP" "$tmp" || faltam="$faltam comparação-exata-com-prd"
    grep -qE "$ALLOW_RE" "$tmp" || faltam="$faltam allowlist-de-destinatário(BOT_TEST_ALLOWLIST)"
    grep -qE "$CAP_RE" "$tmp" || faltam="$faltam cap-por-execução(BOT_MAX_MSGS_PER_RUN)"
    if [ -n "$faltam" ]; then
      n="$(grep -nIE "$ENVIO_RE" "$tmp" | head -1 | cut -d: -f1)"
      achado "$f" "${n:-0}" bot-envio-sem-guard "envio real sem guard DENTRO do provider; faltam:${faltam}. Centralize o envio num provider único com OutboundGuard (piso 18 da engineering)"
    fi
  fi
  rm -f "$tmp"
done

if [ "$envio_real" = 1 ] && [ "$tem_sink" = 0 ]; then
  echo "${raiz}:0: [bot-sem-sink] há envio real e nenhum sink/dry-run: o provider default fora de prd precisa ser o SINK"
  achados=$((achados + 1))
fi

if [ "$verificados" -eq 0 ]; then
  echo "check-bot-effects: nenhum arquivo de código/config em $raiz (exit 2: isto NÃO é aprovação)" >&2
  exit 2
fi
if [ "$achados" -gt 0 ]; then
  echo "check-bot-effects: $achados achado(s) em $verificados arquivo(s)" >&2
  exit 1
fi
echo "check-bot-effects: ok ($verificados arquivo(s) verificados)"
echo "check-bot-effects: estático; o teste de unidade do OutboundGuard (ambiente ∈ {ausente,dev,prod} => sink) continua obrigatório" >&2
