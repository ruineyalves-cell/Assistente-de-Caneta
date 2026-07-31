# Plano de Desenvolvimento — Recorpo

**Data de criação:** 2026-07-16
**Última atualização:** 2026-07-31
**Fonte de verdade:** [docs/PRD.md](PRD.md)
**Alvo de teste:** Samsung Galaxy S25 Ultra (`SM-S938B`, Android 16) via depuração sem fio, validação web no browser.

> **DECISÃO DE ARQUITETURA (fixada):** state management = **`provider`**. `riverpod` foi removido do projeto. Nenhum lote introduz `riverpod`.

---

## Princípios

- Cada lote é **isolado e testável** — o app compila e roda ao fim de cada um.
- Um lote = um foco. Não misturamos identidade visual com feature nova.
- Nenhum lote quebra o fluxo existente (login → dashboard → log → histórico).
- **Warsaw bloqueia build Android local** — validação de UI no web/emulador; CI gera o APK/AAB para o S25.

---

## Resumo de status

| Fase | Lotes | Status |
|---|---|---|
| 0 — Baseline | 0 | ✅ Concluído |
| A — Identidade visual | 1, 2, 3 | ✅ Concluído |
| B — Disclaimer gate | 4 | ✅ Concluído |
| C — Perfil + Dashboard | 5, 6, 7, 8 | ✅ Concluído |
| D — Integrações pesadas | 9, 10, 11, 12, 13 | ✅ Concluído |
| E — Features extras | 14–32.8 | ✅ Concluído |
| F — Segurança + Infra | G1–G8 | ✅ Concluído |
| W — Portal Web | W1–W4 | ✅ Concluído |
| P — Play Store | P1–P4 | 🔧 Em andamento |

---

## FASE 0 — Baseline

### Lote 0 — Confirmar ponto de partida ✅
- App "Assistente de Caneta" abre, faz login, dashboard roxo (streak/score/gráfico), registra o dia, vê histórico.

---

## FASE A — Identidade Visual + Débitos Técnicos

### Lote 1 — Tokens de cor + tema Azul Clínico ✅
- Primária `#2B6CB0`, fundo `#F4F7FA`; tokens centralizados em `constants.dart`.
- Eliminou `Colors.deepPurple` hardcoded.

### Lote 2 — `.withOpacity` → `.withValues` ✅
- 12 ocorrências corrigidas. Zero avisos de deprecação.

### Lote 3 — Cores clínicas de alerta/confirmação ✅
- `#E53E3E` (alerta), `#48BB78` (confirmação) consistentes em todo o app.

---

## FASE B — Disclaimer Gate

### Lote 4 — DisclaimerScreen ✅
- Gate obrigatório LGPD + HIPAA na primeira execução.
- Aceite persistido via `shared_preferences`; botão habilita após rolar até o fim.

---

## FASE C — Semântica de Recomposição

### Lote 5 — ProfileConfigScreen ✅
- Gênero, sexo biológico, eixo farmacológico (5 opções), data da última dose.
- Botão "Gerar Matriz Metabólica". Persistência local + backend.

### Lote 6 — Dashboard de recomposição ✅
- Card de Evolução (peso ±, gordura ↓, massa magra ↑). Foco "Blindagem Muscular".
- Medicação dinâmica baseada no eixo do perfil (removida hardcoded "Mounjaro 10mg").

### Lote 7 — Macros de Blindagem ✅
- Card de proteína estrutural + carboidratos. Atualiza ao registrar log.

### Lote 8 — Gráfico em média móvel ✅
- MetricChart com fl_chart plotando média móvel (não valores brutos).

---

## FASE D — Integrações Pesadas

### Lote 9 — Scanner de refeição (câmera) ✅
- `CameraScannerScreen` com câmera ao vivo e captura.
- Permissão de câmera no manifest.

### Lote 10 — OCR de prescrição ✅
- `DietScannerScreen` via `google_mlkit_text_recognition`.
- Reconhece texto de prescrição impressa e destaca metas nutricionais.

### Lote 11 — Hub Health Connect ✅
- `HealthHubScreen` com autorização Health Connect.
- FC, gasto ativo, passos, sono (READ_SLEEP adicionado ao manifest).

### Lote 12 — Ajuste de esforço ✅
- `EffortScreen` com `EffortAdvisor` service.
- Recomendação de intensidade aeróbica (corrida/ciclismo) por eixo farmacológico.

### Lote 13 — Relatório PDF para o médico ✅
- `ReportPdfService` gera PDF com dados do paciente.
- Preview + share/print via `printing`.

---

## FASE E — Features Extras (além do PRD original)

### Lote 20 — Login social Google ✅
- `SocialAuthService` (Flutter) + `oauthSocial` (backend).
- Web Client ID configurado no Firebase/GCP.
- Android OAuth Client ID pendente (~2026-08-25, Firebase soft-delete).

### Lote 21 — IA de refeição via Gemini ✅
- `MealResultScreen` + `MealRecognitionService`.
- Backend: Gemini Flash Latest primário, OpenAI gpt-4o-mini fallback.
- Zod validation, max 20MB base64, iaLimiter (15 req/min por usuário).

### Lote 22 — Login biométrico ✅
- `BiometricLoginService` com opt-in seguro.
- Fingerprint/face via `local_auth`.

### Lote 23 — Play Billing Premium ✅
- `PaywallScreen` + `PremiumService` (Flutter).
- Backend: validação de purchase, consulta de status (cache 12h), webhook RTDN.
- `FeatureGate` widget + `FeatureUsageService` para limites Free/Pro.

### Lote 25 — Widgets Android ✅
- Home widgets de refeição + água via `home_widget`.
- `WaterWidgetService` para atualização dos dados.

### Lote 27 — Farmacovigilância ✅
- `SymptomsSheet` com chips de sintomas + seletor de intensidade.

### Lote 29 — Onboarding ✅
- `OnboardingScreen` com 3 telas de introdução.
- Exibido apenas na primeira execução.

### Lote 30 — Notificações contextuais ✅
- `NotificationService` via `awesome_notifications`.
- Lembretes de hidratação + check-in com nome do usuário.

### Lote 32 — Quick sheets (Água + Peso) ✅
- `WaterQuickSheet`: +250 / +500 / +750 / +1L, soma na hora.
- `WeightQuickSheet`: input com delta em relação ao último, local (casa/academia/farmácia/clínica).

### Lote 32.2 — Pré-consulta ✅
- `PreConsultaScreen` + endpoint `/pacientes/pre-consulta`.
- Agregação determinística dos logs do mês para o médico.

### Lote 32.3 — Resumo diário ✅
- `DailyTipService` + endpoint `/pacientes/resumo-diario`.
- Resumo determinístico (sem LLM) do dia do paciente.

### Lote 32.4 — Alertas clínicos ✅
- Endpoint `/pacientes/alertas`.
- Alerta objetivo quando sintoma persiste (ex: náusea ≥3 dias seguidos).

### Lote 32.5 — App lock (PIN + biometria) ✅
- `AppLockScreen` + `AppLockSetupScreen` + `AppLockService`.
- PIN + biometria opcional, auto-lock ao sair do app.

### Lote 32.6 — Meus dados LGPD ✅
- `MeusDadosScreen`: exportar dados, listar acessos, excluir conta.
- Conecta com endpoints `/lgpd/*`.

### Lote 32.7 — Dose reminder ✅
- `DoseReminderScreen` com notificação programada.

### Lote 32.8 — Scanner rótulo + bula via Gemini ✅
- `RotuloResultScreen` + `BulaResultScreen`.
- Endpoints `/ia/rotulo` + `/ia/bula`, mesma engine Gemini.

---

## FASE F — Segurança e Infraestrutura

### Lote G1 — Rate limiting por usuário na IA ✅
- `iaLimiter`: 15 req/min por userId. Índices críticos no Postgres.

### Lote G2 — Hardening de segurança P0 ✅
- CORS estrito (CSV de origens, wildcard bloqueado).
- JWT algorithm pinning HS256.
- Refresh token rotation com reuse detection.
- `keys.txt` fora do git. Android backup off.

### Lote G3 — Observabilidade ✅
- Session expiry gracioso.
- Pino logger + Sentry opcional. TODO Redis lockout.

### Lote G4 — Escalabilidade ✅
- `dbRead`/`dbWrite` façades (read replica opcional).
- Scripts de backup Postgres.

### Lote G5 — Performance ✅
- Compressão gzip.
- Resize de fotos IA antes do upload (flutter_image_compress).
- Warm-up com refresh paralelo no cold start.

### Lote G6 — LGPD consent + auditoria ✅
- Middleware `requireConsent` em todos os endpoints de dados de saúde.
- Middleware `audit` registra todas as operações com IP, titular e ação.

### Lote G7 — Auth + testes ✅
- Auth rotation/reuse/lockout testados.
- Cache-Control em `/medicacoes`.

### Lote G8 — CI/CD ✅
- GitHub Actions: build APK/AAB assinado, keep-alive backend, backup Postgres diário (03:00 UTC).
- `targetSdk 35`, `versionCode` auto no CI.
- Conversor SVG → PNG para screenshots Play Store.

---

## FASE W — Portal Web

### Lote W1 — Site institucional ✅
- Landing page com mockup de celular + carrossel de screenshots.
- Páginas: `/privacidade`, `/termos`, `/excluir-conta`, `/status`, `/suporte`.
- SEO/PWA completo. Deploy Vercel (gru1).
- Security headers: CSP, HSTS 1 ano, X-Frame-Options DENY, Permissions-Policy.

### Lote W2 — Portal do paciente Fase 1 ✅
- Login + registro.
- Dashboard + registros + histórico + perfil.
- PWA configurado.

### Lote W3 — Portal do paciente Fase 2 ✅
- Scanner IA (refeição + rótulo + bula) com câmera web.
- Relatório PDF do paciente.
- Meus dados LGPD.
- Vínculo com profissional (convidar/revogar).

### Lote W4 — Portal do profissional ✅
- Login profissional.
- Lista de pacientes vinculados.
- Ficha do paciente + download relatório PDF.

---

## FASE P — Publicação Play Store 🔧

Roteiro detalhado em [docs/PLANO_GOOGLE_PLAY.md](PLANO_GOOGLE_PLAY.md).

### P1 — Preparação técnica 🔧
- [x] Conta Play Console paga (US$25)
- [x] CI gerando APK/AAB assinado
- [x] `targetSdk 35`
- [x] Ícone e feature graphic (draft)
- [x] Screenshots Play Store (4 SVG → PNG)
- [x] Política de privacidade e termos online
- [x] Página `/excluir-conta` publicada
- [x] 10 declarações Play Console preenchidas
- [x] Ficha da Loja completa
- [x] `applicationId` → `br.com.recorpo.app` (já em build.gradle.kts)
- [x] Release keystore + CI configurados (secrets no GitHub Actions)

### P2 — Teste fechado
- [ ] Upload primeiro AAB Internal Testing
- [ ] 20 testers conhecidos
- [ ] Coleta de feedback

### P3 — Produção + Premium
- [x] Merchant Center + SKUs Play Billing (recorpo_premium_monthly R$ 19,90/mês + recorpo_premium_yearly R$ 199,90/ano, ambos ativos)
- [ ] Android OAuth Client ID (~2026-08-25)
- [x] Setar `RTDN_SHARED_SECRET` no Render (configurado 2026-07-31)
- [ ] Publicação em produção Play Store BR
- [ ] Ativar Premium R$ 19,90/mês

### P4 — Marketing orgânico
- [ ] Instagram + WhatsApp + grupos
- [ ] Meta: 20 assinantes = R$ 400 MRR em 12 semanas

---

## Lotes futuros (candidatos)

| Lote | Descrição | Prioridade |
|---|---|---|
| ~~L33~~ | ~~Migrar JWT portal profissional → httpOnly cookie~~ | ✅ Resolvido |
| L34 | Nonce-based CSP (requer Next 15) | Média |
| L35 | Apple Sign-In (iOS) | Média (pré-requisito iOS) |
| L36 | Sync backend peso/sintomas (real-time) | Média |
| L37 | Redis para login lockout (atualmente in-memory) | Baixa |
| L38 | iOS build + App Store | Futuro |

---

## Contagem final

| Componente | Total |
|---|---|
| Features Flutter (telas + serviços) | 26 funcionalidades |
| Endpoints API | 34 |
| Páginas web | 18 |
| Lotes concluídos | 40+ |
| Lotes pendentes (Play Store) | 4 passos |
