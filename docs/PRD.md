# PRD — Recorpo

**Produto:** Recorpo (Assistente de Caneta)
**Data:** Julho de 2026
**Posicionamento:** Plataforma clínica focada em Recomposição Corporal para usuários de terapias metabólicas (GLP-1, Duplos/Triplos Agonistas, Inibidores de Miostatina). Copiloto para pacientes e profissionais de saúde, com IA de Visão, monitoramento de composição corporal e conformidade regulatória (LGPD/HIPAA).

---

## 1. Visão Estratégica

O mercado de apps de emagrecimento foca na logística de venda de GLP-1 e na perda de peso absoluta. O Recorpo ataca a complicação metabólica emergente: a Obesidade Sarcopênica (perda severa de massa magra durante o tratamento).

- **Paradigma:** transição de "Perda de Peso" para "Recomposição Corporal" (blindagem de massa magra).
- **Modelo:** B2C freemium (Free + Premium R$ 19,90/mês ou R$ 199,90/ano via Play Billing no Android + Stripe no web/iOS). B2B2C com portal do profissional previsto para expansão.
- **Regulatório:** app educacional, fora do escopo Anvisa. Disclaimer LGPD + HIPAA como gate obrigatório.

---

## 2. Identidade Visual

- **Marca:** Recorpo (registro INPI pendente)
- **Paleta por eixo funcional:**

| Eixo | Cor | Hex |
|---|---|---|
| Refeição | Laranja vivo | `#FF8C42` |
| Água | Azul água | `#4FC3F7` |
| Peso | Verde menta | `#66BB6A` |
| Sintomas | Lilás suave | `#AB47BC` |
| Streak | Dourado quente | `#FFB74D` |
| Movimento | Coral energético | `#EF5350` |

- **Base:** dark-first (tema escuro como padrão), gerenciado via `lib/utils/theme.dart`
- **Cores semânticas:** Azul Clínico `#2B6CB0` (primária), Fundo Frio `#F4F7FA` (superfícies claras), Vermelho Alerta `#E53E3E`, Verde Confirma `#48BB78`

---

## 3. Arquitetura Técnica

### 3.1 Flutter (Mobile)

- **State management:** Provider (decisão fixada; riverpod removido)
- **Estrutura:** ~60 arquivos Dart, ~8500 linhas
- **Target:** Android (Galaxy S25 Ultra, Android 16); iOS futuro
- **Dependências-chave:** dio, flutter_secure_storage, provider, fl_chart, camera, image_picker, google_mlkit_text_recognition, google_mlkit_image_labeling, health, pdf, printing, home_widget, awesome_notifications, google_sign_in, in_app_purchase, local_auth, crypto, flutter_image_compress

### 3.2 Backend (Node.js)

- **Stack:** Express + PostgreSQL (Render)
- **Segurança:** bcrypt cost 12, JWT HS256 com algorithm pinning, refresh token rotation com reuse detection, AES-256-GCM field encryption, rate limiting (4 camadas), Helmet, HSTS, CSP
- **37 endpoints** organizados em: Auth (5), Medicações (2), LGPD (5), Paciente (10), IA (3), Assinaturas (6: 3 Play + 3 Stripe), Portal Profissional (3), Logs (3)
- **IA:** Gemini Flash Latest (primário) + OpenAI gpt-4o-mini (fallback), Zod validation, max 20MB base64

### 3.3 Web (Next.js 14)

- **Stack:** Next.js 14 + Tailwind + Framer Motion, deploy Vercel (região gru1)
- **Domínio:** www.recorpo.com.br
- **Security headers:** CSP, HSTS 1 ano, X-Frame-Options DENY, Permissions-Policy (câmera permitida só em /app/*)

---

## 4. Funcionalidades — App Flutter

### Fase A — Identidade Visual e Débitos Técnicos (Lotes 1-3) ✅

| # | Funcionalidade | Descrição |
|---|---|---|
| L1 | Tema Azul Clínico | Paleta `#2B6CB0` / `#F4F7FA`, tokens de cor centralizados |
| L2 | Deprecações corrigidas | `.withOpacity` → `.withValues` (12 ocorrências) |
| L3 | Cores clínicas | Alertas `#E53E3E` / confirmação `#48BB78` consistentes |

### Fase B — Disclaimer Gate (Lote 4) ✅

| # | Funcionalidade | Descrição |
|---|---|---|
| L4 | DisclaimerScreen | Gate obrigatório LGPD + HIPAA, aceite persistido via shared_preferences, rolagem até o fim para habilitar botão |

### Fase C — Perfil e Dashboard (Lotes 5-8) ✅

| # | Funcionalidade | Descrição |
|---|---|---|
| L5 | ProfileConfigScreen | Gênero, sexo biológico, eixo farmacológico (5 opções), data da última dose, "Gerar Matriz Metabólica" |
| L6 | Dashboard recomposição | Card de Evolução (peso ±, gordura ↓, massa magra ↑), foco "Blindagem Muscular", medicação dinâmica (não hardcoded) |
| L7 | Macros de Blindagem | Card de proteína estrutural + carboidratos no dashboard |
| L8 | Gráfico média móvel | MetricChart com fl_chart plotando média móvel suavizada |

### Fase D — Integrações (Lotes 9-13) ✅

| # | Funcionalidade | Descrição |
|---|---|---|
| L9 | CameraScannerScreen | Câmera ao vivo + captura de refeição para análise IA |
| L10 | DietScannerScreen | OCR de prescrição nutricional via google_mlkit_text_recognition |
| L11 | HealthHubScreen | Health Connect: FC, gasto ativo, passos, sono (READ_SLEEP) |
| L12 | EffortScreen | Ajuste de intensidade aeróbica (corrida/ciclismo) por eixo farmacológico |
| L13 | ReportScreen + PDF | Relatório com dados do paciente, geração PDF, share/print |

### Fase E — Extras além do PRD original (Lotes 14-32.8) ✅

| # | Funcionalidade | Tela/Serviço |
|---|---|---|
| L20 | Login social Google | SocialAuthService + OAuth backend |
| L21 | IA de refeição (Gemini) | MealResultScreen + MealRecognitionService |
| L22 | Login biométrico | BiometricLoginService (opt-in, fingerprint/face) |
| L23 | Play Billing Premium | PaywallScreen + PremiumService + backend validation |
| L25 | Widgets Android | Home widgets (refeição + água) via home_widget |
| L27 | Farmacovigilância | SymptomsSheet com intensidade + chips |
| L29 | Onboarding | OnboardingScreen (3 telas de introdução) |
| L30 | Notificações contextuais | NotificationService (hidratação + check-in) via awesome_notifications |
| L32 | Quick sheets | WaterQuickSheet (+250/500/750/1L), WeightQuickSheet (delta + local) |
| L32.2 | Pré-consulta | PreConsultaScreen + endpoint determinístico |
| L32.3 | Resumo diário | DailyTipService + endpoint backend |
| L32.4 | Alertas clínicos | Sintoma persistente → alerta objetivo |
| L32.5 | App lock (PIN + biometria) | AppLockScreen + AppLockSetupScreen + AppLockService |
| L32.6 | Meus dados LGPD | MeusDadosScreen (exportar, acessos, excluir conta) |
| L32.7 | Dose reminder | DoseReminderScreen |
| L32.8 | Scanner rótulo + bula | RotuloResultScreen + BulaResultScreen via Gemini |

### Funcionalidades transversais

| Funcionalidade | Descrição |
|---|---|
| Feature gate | `FeatureGate` widget + `FeatureUsageService` (Free/Pro limites) |
| Skeleton loading | `DashboardSkeleton` (loading nativo, sem shimmer) |
| Pull-to-refresh | Refresh + cache local + retry silencioso |
| IndexedStack nav | Troca de aba instantânea (não rebuilda) |
| FloatingNavBar | Navegação inferior flutuante |
| Greeting service | Saudação contextual por hora do dia |
| Theme controller | Dark-first, alternância light/dark |
| Image prep | Compressão + resize de fotos antes do upload IA |
| Validators | Validação de entrada centralizada |

---

## 5. Funcionalidades — Portal Web

### 5.1 Site institucional (www.recorpo.com.br)

| Página | Rota | Descrição |
|---|---|---|
| Landing page | `/` | Hero com mockup de celular, carrossel de screenshots, CTA Play Store |
| Privacidade | `/privacidade` | Política de privacidade completa |
| Termos | `/termos` | Termos de uso |
| Excluir conta | `/excluir-conta` | Formulário LGPD + Play Store policy |
| Status | `/status` | Status do backend |
| Suporte | `/suporte` | Contato e FAQ |

### 5.2 Portal do paciente (`/app/*`)

| Página | Rota | Descrição |
|---|---|---|
| Login | `/app/login` | Autenticação email/senha |
| Registro | `/app/registro` | Cadastro de paciente |
| Dashboard | `/app` | Visão geral, registros do dia |
| Histórico | `/app/historico` | Timeline de registros |
| Perfil | `/app/perfil` | Edição de perfil |
| Meus dados | `/app/meus-dados` | LGPD: exportar, acessos, excluir |
| Scanner refeição | `/app/scan/refeicao` | IA de refeição via câmera web |
| Scanner rótulo | `/app/scan/rotulo` | IA de rótulo alimentar |
| Scanner bula | `/app/scan/bula` | IA de bula de medicamento |

### 5.3 Portal do profissional (`/portal/*`)

| Página | Rota | Descrição |
|---|---|---|
| Login | `/portal/login` | Autenticação profissional |
| Lista pacientes | `/portal/pacientes` | Pacientes vinculados |
| Ficha paciente | `/portal/paciente/[id]` | Dados + relatório PDF do paciente |

---

## 6. API Backend — Endpoints (37)

### Auth (5)
`POST /auth/registrar` · `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `POST /auth/oauth-social`

### Medicações (2)
`GET /medicacoes` · `GET /medicacoes/:id`

### LGPD (5)
`POST /lgpd/consentimento` · `GET /lgpd/consentimentos` · `GET /lgpd/exportar` · `GET /lgpd/acessos` · `DELETE /lgpd/conta`

### Paciente (10)
`PUT /pacientes/perfil` · `GET /pacientes/perfil` · `GET /pacientes/pre-consulta` · `GET /pacientes/alertas` · `GET /pacientes/resumo-diario` · `GET /pacientes/meu-relatorio.pdf` · `GET /pacientes/profissionais` · `POST /pacientes/profissionais` · `DELETE /pacientes/profissionais/:id`

### Logs (3)
`POST /logs` · `GET /logs` · `GET /logs/dashboard`

### IA de Visão (3)
`POST /ia/refeicao` · `POST /ia/rotulo` · `POST /ia/bula`

### Assinaturas (3 Play + 3 Stripe = 6)
`POST /assinaturas/validar` · `GET /assinaturas/status` · `POST /assinaturas/rtdn`
`POST /stripe/checkout` · `POST /stripe/webhook` · `POST /stripe/portal`

### Portal Profissional (3)
`GET /portal/pacientes` · `GET /portal/pacientes/:id` · `GET /portal/pacientes/:id/relatorio.pdf`

---

## 7. Segurança

### Positivos confirmados (auditoria 2026-07-30)
- Zero SQL injection (queries 100% parametrizadas)
- JWT algorithm pinning HS256
- Refresh token rotation com reuse detection
- bcrypt cost 12
- AES-256-GCM para campos sensíveis
- Rate limiting em 4 camadas (global, auth, IA por usuário, assinaturas)
- Logger com redação automática de dados sensíveis
- Segredos fora do git (.env, .jks, .pem, google-services.json)
- CORS estrito (CSV de origens, wildcard bloqueado)
- HSTS 1 ano + preload
- Android backup off, flutter_secure_storage para tokens

### Achados médios
1. ~~Portal profissional web armazena JWT em `localStorage`~~ — **Resolvido** (migrado para httpOnly cookie + in-memory access token, mesmo padrão do /app)
2. CSP com `unsafe-inline` + `unsafe-eval` — avaliar nonce-based na migração Next 15
3. ~~RTDN webhook sem auth quando `RTDN_SHARED_SECRET` não está setado~~ — **Resolvido** (secret configurado no Render em 2026-07-31)
4. ~~Portal do paciente web usava `<a>` para navegação interna, causando full reload e perda do access token em memória~~ — **Resolvido** (migrado para `<Link>` do Next.js, navegação client-side preserva sessão)

---

## 8. Pendências Operacionais

| Item | Responsável | Prazo estimado |
|---|---|---|
| Merchant Center + SKUs Play Billing | Manual (Play Console) | Pré-publicação |
| Upload primeiro AAB para Internal Testing | Manual (Play Console) | Pré-publicação |
| Android OAuth Client ID (Firebase soft-delete expira) | Manual (Firebase/GCP) | ~2026-08-25 |
| Setar RTDN_SHARED_SECRET no Render | Manual (Render dashboard) | Antes de ativar Premium |
| Criar conta Stripe + 2 produtos (mensal + anual) | Manual (Stripe dashboard) | Pré-publicação |
| Setar 5 env vars Stripe no Render (keys + price IDs) | Manual (Render dashboard) | Pré-publicação |
| Configurar webhook Stripe → backend/api/stripe/webhook | Manual (Stripe dashboard) | Pré-publicação |
| Rodar migration 005_stripe.sql no Postgres | Manual (psql ou Render) | Pré-publicação |
| ~~Migrar JWT portal profissional → httpOnly~~ | ~~Dev~~ | ✅ Resolvido |
