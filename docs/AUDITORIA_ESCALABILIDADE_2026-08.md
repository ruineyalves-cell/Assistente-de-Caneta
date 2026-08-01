# Recorpo — Auditoria de Escalabilidade & Fluidez (2026-08)

> **Objetivo:** validar a arquitetura para escalar de 1 a 500+ usuários mantendo UI sem engasgos, e registrar as decisões tomadas.
> **Origem:** checklist técnico (estresse de arquitetura) cruzado com o código real, revisado por dois engenheiros sênior.
> **Data:** 2026-08-01. Este arquivo é fonte de verdade das decisões abaixo.

---

## 0. Correção de premissa (importante)

O checklist original assumia **Cloudflare D1 + Workers + KV** (arquitetura serverless na borda). **O Recorpo não roda nesse stack.** O que está em produção:

| Camada | Realidade |
|---|---|
| Backend | Node/Express no **Render** (plano Starter pago, sem cold start) |
| Banco | **Postgres** (`pg` pool, `max=5`/instância, read/write split já abstraído em `config/db.js`) |
| App | **Flutter** + **Provider** (ChangeNotifier) + **shared_preferences** |
| Cache | HTTP `Cache-Control` (catálogo de medicações) + cache em Postgres (status de assinatura, TTL 12h). **Sem Redis/KV.** |
| Fila/Workers | **Não existe.** PDF é gerado client-side no app; o do backend é síncrono. |

Itens do checklist sobre "rotação de token do D1", "rate limit do D1" e "isolamento de crons em instância" não se aplicam literalmente — foram respondidos pelo equivalente real.

## 1. Diagnóstico (o que já está bom)

- **Escrita otimista + fila durável** nos registros diários (`services/logs_provider.dart`): salva local e reflete na tela antes do backend; fila `pending_log_writes_v1` sobrevive a fechar o app.
- **Índices críticos** presentes (`database/migrations/003_indexes.sql`): a query mais quente (`daily_logs` por `patient_id, log_date DESC`) e índices parciais para refresh tokens, purga LGPD e consents.
- **Virtualização** do histórico via `ListView.builder`; backend limita `listar` a `LIMIT 90`.
- **Assets já vetorizados** (ícones Material/Cupertino + `fl_chart`); sem PNG pesado no bundle.
- **Observabilidade backend**: Sentry (`@sentry/node`) + `pino` estruturado + `logSeguranca`.
- **Rate limiting** dimensionado por rota (`middleware/rateLimiter.js`).

## 2. Buracos reais e priorização

| # | Achado | Severidade | Fase |
|---|---|---|---|
| A | **Sem crash-tracking no app Flutter** — crashes no celular do usuário eram invisíveis | P0 | 1 |
| B | **Sem timeout nas chamadas de IA** (Gemini/OpenAI) — socket podia ficar pendurado | Alta | 1 |
| C | **Migration nova pulada por falta de OWNER** era enterrada só no log (bomba-relógio) | Média | 1 |
| D | **`main.dart` monolítico (3366 linhas)** com rebuild amplo — engasgo em aparelho antigo | Alta (UX) | 3 |
| E | Boot confia em `IF NOT EXISTS` + tolerância a erro pra saber o que já rodou (sem ledger) | Média | 2 |
| F | Rate-limit e contador de brute-force **em memória** (quebra com 2ª instância) | Baixa (hoje) | Backlog |
| G | Fila de PDF no backend | Baixa | Backlog (só se PDF voltar pro servidor) |

## 3. Decisões travadas

1. **Observabilidade do app = Sentry Flutter** (não Crashlytics). Motivo: unifica com o `@sentry/node` do backend **e** entrega performance tracing (responde "a tela X demorou >2s?"), fechando duas lacunas de uma vez. Trade-off aceito: Crashlytics cobriria melhor crash nativo/ANR, mas fragmentaria a observabilidade.
2. **Sequência do refactor de UI:** decompor `main.dart` → `const`/`RepaintBoundary` → `Selector`/`context.select` → **só então** redesign da Home. Nunca redesenhar sobre o monolito. `Selector` sozinho não garante 60fps.
3. **Migration:** alerta no Sentry agora (band-aid); tabela `schema_migrations` (ledger) é o fix estrutural (Fase 2).
4. **Timeout de IA generoso (28s):** visão multimodal é legitimamente lenta; o timeout existe pra impedir socket pendurado, não pra cortar request lenta legítima.

## 4. Fase 1 — implementado (2026-08-01)

| Item | Mudança | Arquivos |
|---|---|---|
| 1.1 Sentry Flutter | `SentryFlutter.init` com `appRunner`; `SentryNavigatorObserver` no `MaterialApp`; `tracesSampleRate=0.2`; `sendDefaultPii=false`; `beforeSend` faz scrub de dado de saúde/credencial (LGPD). Ativa **só** com `--dart-define=SENTRY_DSN` (sem DSN → desligado, nada sai do device). | `flutter_app/pubspec.yaml`, `flutter_app/lib/main.dart` |
| 1.2 Timeout IA | `_fetchComTimeout` (AbortController, 28s, env `IA_TIMEOUT_MS`) nas chamadas Gemini/OpenAI; `_responderErroIA` distingue **504** (timeout) de **502** (falha da IA). +4 testes. | `backend/src/controllers/iaController.js`, `backend/tests/iaController.test.js` |
| 1.3 Alerta de migration | `capturarAviso()` (log warn + `Sentry.captureMessage` nível warning) no branch `42501` do boot. | `backend/src/utils/logger.js`, `backend/src/server.js` |
| CI | `--dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN_FLUTTER }}` nos builds APK e AAB. | `.github/workflows/build-android-apk.yml` |

**Verificação:** backend `npm test` = 117/117 (4 novos); Flutter `pub get` resolve `sentry_flutter 8.14.2`; `flutter analyze lib/main.dart` sem erros/warnings.

### Ação manual pendente (fora do código)
- [ ] Criar projeto **Sentry Flutter** e adicionar o secret **`SENTRY_DSN_FLUTTER`** no GitHub (Settings → Secrets → Actions). Sem ele, o APK builda mas o Sentry fica desligado.
- [ ] (Opcional) Ligar tracing no backend: hoje `tracesSampleRate: 0` em `logger.js`. Subir pra ~0.1 quando quiser trace ponta-a-ponta app↔API.

## 5. Fase 2 — resiliência de deploy — implementado (2026-08-01)

Ledger de migrations (`schema_migrations`) substitui o "adivinhar via IF NOT EXISTS + tolerância a erro".

| Mudança | Arquivos |
|---|---|
| Runner extraído pra módulo injetável e **testável** (recebe `db`/`logger`/`capturarAviso`/`dir`). Cria a tabela `schema_migrations` no próprio runner (não como arquivo de migration → evita ovo-e-galinha). Checa o ledger antes de rodar cada `.sql`; registra só em sucesso. | `backend/src/config/migrator.js` (novo), `backend/src/server.js` |
| **Backfill automático** na 1ª introdução: ledger vazio + tabela base `users` existe → marca todas as migrations atuais como aplicadas **sem executar** (evita re-rodar ALTER antiga e cair no `42501`). Banco novo (sem `users`) roda tudo. | idem |
| 5 testes: banco novo, banco estabelecido (backfill), boot seguinte, migration nova com `42501` (alerta + não registra → re-tentável), erro não-`42501` fatal. | `backend/tests/migrator.test.js` (novo) |

**Resultado:** migration nova que falhe por OWNER **não** é registrada → continua re-tentável e dispara `migration_skip_permission` no Sentry a cada boot. Deixa de ser skip silencioso.

**Verificação:** `npm test` = 122/122 (5 novos). Em produção, no 1º boot pós-deploy, esperar o log `evento: migration_backfill` uma vez; nos seguintes, os arquivos aparecem como `migration_skip_ledger` (nível debug).

## 6. Fase 3 — fundação de performance da UI (antes do redesign)

Decompor `DashboardPage` de `main.dart` em widgets por card (mover pra `lib/screens/home/`), `const` + `RepaintBoundary` nos cards, e `Selector<LogsProvider, T>` no lugar do `Consumer` amplo.

### Fatia piloto entregue (2026-08-01) — padrão de referência

- `lib/screens/home/home_consistencia_row.dart` (novo): extrai a linha **streak + score** do `Consumer<LogsProvider>` gigante. Usa as 3 técnicas combinadas: widget `const` (corta o cascade de rebuild do pai) + `Selector<LogsProvider,int>` por card (só reconstrói quando o próprio número muda) + `RepaintBoundary`.
- `main.dart`: bloco inline (17 linhas) → `const HomeConsistenciaRow()`; imports órfãos de `StreakBadge`/`ScoreCard` removidos.
- Verificação estática: `flutter analyze` do projeto = **0 erros / 0 warnings** (50 infos pré-existentes).

**VALIDAÇÃO NO S25 (você):** abrir a Home com o Flutter DevTools → aba *Performance* / *Rebuild counts*. Encher a barra de água (dispara `notifyListeners`) e confirmar que **streak e score NÃO aparecem no rebuild** (só o que mudou). Se confirmar, eu replico o mesmo padrão nos outros cards (água, peso, sintomas, refeições) — que hoje ainda estão dentro do Consumer amplo.

**Critério final da fase:** encher a água reconstrói só o card de água; hero a 60fps em aparelho antigo.

## 7. Backlog gated em escala — NÃO fazer agora

| Item | Quando | Trava |
|---|---|---|
| Upstash Redis (rate-limit + brute-force) | Ao ligar 2ª instância/autoscaling no Render | **Não habilitar 2ª instância sem Redis antes** — senão os limites furam (viram per-instância) |
| Ativar `DATABASE_READ_URL` (réplica) | Quando p95 de `/logs/dashboard` subir no Sentry | Código já pronto em `config/db.js`; suspeito nº1 é o decrypt de campo em Node |
| Fila de PDF (worker) | Só se o PDF voltar pro backend | Hoje é client-side; desnecessário |

## 8. Nota de carga (calibração honesta)

Postgres + índices aguentam **500 DAU** tranquilo. Para **500 simultâneos** de verdade, o gargalo não é o banco — é a **CPU da instância Starter** (PDF/decrypt/base64) e o **pool `max=5`/instância**. Ação: nenhuma agora, só **instrumentar** (o tracing da Fase 1 dá o sinal). Quando o p95 subir, a resposta é `DATABASE_READ_URL` ou subir instância — ambos sem refatoração.
