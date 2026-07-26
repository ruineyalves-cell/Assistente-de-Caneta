# Roadmap do site — Recorpo Web

Escopo estratégico e ordenado do que faz sentido replicar do app no site
`www.recorpo.com.br`, com trade-offs registrados. Regra guia: **o site
não deve competir com o app** — deve ser (a) porta de entrada, (b) canal
alternativo pra funcionalidades que se beneficiam de tela grande.

---

## Já entregue

| Rota | Função |
|---|---|
| `/` | Landing + hero mockup + galeria de screenshots + CTA download |
| `/privacidade` | Política LGPD (fonte de verdade legal) |
| `/termos` | Termos de uso |
| `/suporte` | FAQ + contato |
| `/status` | Health check público do backend (I2) |
| `/portal/login` | Login profissional |
| `/portal/pacientes` | Lista de pacientes vinculados |
| `/portal/paciente/[id]` | Dashboard + PDF do paciente |

---

## O que NÃO deve ir pro site (justificativa técnica)

Antes do "vamos migrar tudo": há coisas que quebram no navegador ou
minam o valor do app.

| Feature do app | Por que não no site |
|---|---|
| **Health Connect** | Não existe no web. Ponto. |
| **Notificações locais** (dose, hidratação) | Web notifications são frágeis, precisam permissão, som depende do SO, iOS bloqueia. App nativo é a UX certa. |
| **PIN + biometria** | WebAuthn seria opção, mas fricção alta pra fluxo do site (que já exige senha do backend). |
| **Widget de água** (Android) | Só existe no launcher Android. |
| **Câmera nativa (scanners IA)** | `getUserMedia` funciona, mas UX é pior — sem overlay guia, sem torch, sem foco automático. Fica opcional (F2). |

---

## Prioridade 1 — Fluxo Paciente Web (autoatendimento)

Um paciente que fez download parcial do app OU que prefere abrir do
computador durante consulta. Todas essas telas já têm API pronta no
backend — só falta o front.

| # | Rota | Endpoint backend já existe | Esforço |
|---|---|---|---|
| P1 | `/paciente/login` (mesma tela do portal, role paciente) | `/auth/login` | ~30min |
| P2 | `/paciente` — dashboard resumo (peso atual, streak, próxima dose) | `/pacientes/perfil`, `/logs?limit=30` | ~2h |
| P3 | `/paciente/logs` — registrar/ver logs (peso, água, refeição, sintomas) | `/logs` GET/POST | ~2h |
| P4 | `/paciente/resumo-diario` — o mesmo texto determinístico do app | `/pacientes/resumo-diario` | ~30min |
| P5 | `/paciente/meus-dados` — exportar LGPD + histórico de acessos + excluir conta | `/lgpd/exportar`, `/lgpd/acessos`, `DELETE /lgpd/conta` | ~1h |
| P6 | `/paciente/pre-consulta` — mesma engine determinística | `/pacientes/pre-consulta` | ~40min |
| P7 | `/paciente/profissionais` — vincular/desvincular médico | `/pacientes/profissionais` | ~40min |

**Total**: ~8h de implementação. Alto valor: paciente sem Android continua no ecossistema.

## Prioridade 2 — Extras que aproveitam tela grande

| # | Feature | Ganho | Esforço |
|---|---|---|---|
| F1 | Portal médico — filtros/busca na lista de pacientes | Escala pra médicos com 50+ pacientes | ~1h |
| F2 | Scanner de bula/rótulo via upload de arquivo (não câmera) | Paciente pode escanear no PC | ~1h (reusa `/ia/rotulo`, `/ia/bula`) |
| F3 | Comparativo de gráficos (peso, água, proteína lado a lado) | Só no desktop faz sentido | ~2h |
| F4 | Impressão do PDF direto do portal (evita download) | Fluxo médico | ~30min |

## Prioridade 3 — Marketing e institucional

| # | Página | Motivo |
|---|---|---|
| M1 | `/blog` (MDX estático) | SEO orgânico "acompanhamento GLP-1", "efeitos Ozempic", etc. |
| M2 | `/precos` clean e comparativo Free × Premium | Reforço da conversão |
| M3 | `/parceiros` — clínicas afiliadas (form de contato) | B2B |

---

## Auditoria de segurança do site (Lote I6)

### 🟢 Aplicado agora

- **Security headers em toda rota** (`next.config.mjs`):
  - **CSP** com origem pinada pra API do Render — bloqueia XSS de terceiros
  - **HSTS** 1 ano + preload → força HTTPS pra sempre
  - **X-Frame-Options: DENY** + `frame-ancestors 'none'` na CSP → bloqueia clickjacking
  - **X-Content-Type-Options: nosniff** → impede MIME sniffing
  - **Referrer-Policy: strict-origin-when-cross-origin** → não vaza URLs pra terceiros
  - **Permissions-Policy** desliga câmera/mic/geo/pagamento/USB → superfície zero

### 🟡 Aceito com plano

- **JWT em `localStorage`** (`web/lib/api.ts`): vulnerável a XSS, mas
  não há vetor real hoje (zero scripts de 3ª parte, CSP restrita).
  **Plano de migração**: quando o backend adicionar endpoint
  `/auth/portal-cookie` que setar cookie httpOnly + SameSite=Lax,
  refatorar `api.ts` pra usar credentials: 'include' e remover o
  localStorage.

### 🟢 Sem risco identificado

- Zero `dangerouslySetInnerHTML`, zero `eval`, zero manipulação
  direta de `document.cookie`.
- Backend já valida JWT algorithms explicitamente (Lote S2c) — token
  não pode ser rebaixado a `none`.
- Rate limit do backend cobre login/registro (`authLimiter`) e IA
  (`iaLimiter`), então mesmo com API pública o portal está protegido.

### 🔒 Nunca fazer no site

- Nunca colocar `GEMINI_API_KEY` ou outra chave server-side em variável
  `NEXT_PUBLIC_*` — isso a exporia no bundle do browser. Tudo que fala
  com IA continua indo via backend (`/api/ia/*`).
- Nunca ativar `dangerouslyAllowSVG` do `next/image` se o SVG vier de
  usuário — SVG pode conter `<script>`. Nossos SVGs são fonte
  controlada e viram PNG antes de ir pro público.
- Nunca aceitar `redirect` de URL vindo de query string sem validar
  contra allowlist — vetor clássico de phishing.
