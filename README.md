# schematize-bots — bots para Discord, Telegram e similares

> **Bot é credencial de longa vida + entrada pública + efeito externo em massa.** Token em cofre,
> assinatura verificada, ack no prazo, 429 respeitado, entrada do usuário nunca confiável e nenhuma
> mensagem real fora de prd.

Pacote de **skill normativa para [Claude Code](https://claude.com/claude-code)**.
Parte do catálogo **schematize skills**.

## Instalar

```bash
schematize install bots    # requer o CLI schematize instalado
```

Manual:

```bash
T="$(mktemp -d)"   # nunca /tmp fixo
git clone https://github.com/schematizeme/skill-bots.git "$T/skill-bots"
bash "$T/skill-bots/install.sh" .        # instala em .claude/ do projeto atual
```

## O que tem dentro

- **SKILL.md** — o contrato: 14 pisos, fronteiras com as demais skills e o mapa de references.
- **references/** — credenciais, transporte e assinatura, prazo/fila/rate limit, comandos e intents,
  moderação e privacidade, ambientes e efeito externo, `stack-versoes` (anexo volátil com fonte e data).
- **scripts/** — `check-bot.sh` (gate estático, waiver `bot-ok:`), `check-bot-effects.sh` (piso 18: sink, guard, cap) e os `.test.sh`.
- **assets/** — `CLAUDE.md` sempre-on e comandos `/bot-*`.
