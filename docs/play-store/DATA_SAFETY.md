# Google Play — Data Safety (Segurança de dados)

Respostas pré-preenchidas para o formulário **Data Safety** do Play
Console (App content → Data safety). Baseado no código real do Recorpo
(auditoria em 2026-07-26): backend com criptografia AES-256-GCM em
repouso, TLS em trânsito, LGPD nativo (exportar/excluir), zero venda a
terceiros, opt-in por consentimento em cada seção de saúde.

Cole as respostas na ordem exata do formulário do Console. Cada
subseção abaixo mapeia 1:1 com as perguntas do wizard.

---

## Section 1 — Data collection and security

**Does your app collect or share any of the required user data types?**

→ **Sim**. Coletamos dados de conta, saúde e uso do app.

**Is all of the user data collected by your app encrypted in transit?**

→ **Sim**. Todo tráfego é HTTPS/TLS 1.2+. `usesCleartextTraffic="false"`
no manifest. Network Security Config bloqueia CAs de usuário.

**Do you provide a way for users to request that their data is deleted?**

→ **Sim**. O usuário exclui a conta dentro do próprio app
(Perfil → Meus Dados → Excluir minha conta). Ao confirmar, soft delete
imediato + purga definitiva em 30 dias (LGPD art. 18 VI). Alternativa
por e-mail: `recorpoapp@gmail.com`.

---

## Section 2 — Data types (what you collect)

### Personal info

| Data type | Collected? | Shared? | Optional? | Purpose |
|---|---|---|---|---|
| **Name** | Sim | Não | Sim | Personalização da conta |
| **Email address** | Sim | Não | Não | Login + comunicação essencial |
| **User IDs** | Sim | Não | Não | Auth (JWT interno) |
| Address, phone, race, political, sexual orientation, other | **Não** | — | — | — |

### Health and fitness

| Data type | Collected? | Shared? | Optional? | Purpose |
|---|---|---|---|---|
| **Health info** (peso, IMC, hidratação, refeições, sintomas, medicação, doses) | Sim | Não | Sim (por consentimento LGPD explícito na 1ª execução) | Acompanhamento de tratamento (App functionality) |
| **Fitness info** (passos, calorias ativas, sono via Health Connect) | Sim | Não | Sim (opt-in por permissão do Health Connect) | Contexto pro dashboard (App functionality) |

### Financial info

| | |
|---|---|
| **Purchase history** | Sim (gerenciado pelo Google Play; recebemos apenas confirmação de assinatura ativa) |
| Credit card, bank, other | **Não** — Play Billing cuida de tudo, nunca vemos dados de pagamento |

### App activity

| Data type | Collected? | Shared? | Optional? | Purpose |
|---|---|---|---|---|
| **App interactions** (registros diários, uso de scanners IA) | Sim | Não | Não | App functionality + Analytics interno agregado |
| **In-app search history** | Não | — | — | — |
| **Installed apps** | Não | — | — | — |
| **Other user-generated content** (fotos capturadas pelos scanners) | Sim (só em memória, não persiste) | Sim, com Google (Gemini API) | Sim, só quando usuário usa scanner | App functionality (análise IA da imagem) |

### App info and performance

| Data type | Collected? | Shared? | Optional? | Purpose |
|---|---|---|---|---|
| **Crash logs** | Sim (se `SENTRY_DSN` configurada; anonimizados) | Sim, com Sentry (processador) | Não | Analytics / correção de bugs |
| **Diagnostics** | Sim (métricas de latência) | Não | Não | Analytics |
| **Other app performance data** | Não | — | — | — |

### Device or other IDs

| Data type | Collected? | Shared? | Optional? | Purpose |
|---|---|---|---|---|
| **Device or other IDs** | Não | — | — | — |

### NÃO coletamos

- Localização precisa/aproximada
- Contatos, calendário, SMS
- Fotos/vídeos além das capturas explícitas dos scanners
- Mensagens
- Áudio (mic nunca solicitado)
- Arquivos ou docs além dos scanners
- Web browsing history

---

## Section 3 — Data usage and handling

### For each data type declared above:

**Purposes** (marcar todos que se aplicam):
- App functionality → **Sim** em TODOS
- Analytics → **Sim** para health info, app interactions (agregados)
- Developer communications → apenas email
- Advertising or marketing → **Não** em nenhum
- Fraud prevention, security, and compliance → **Sim** para email, user IDs
- Personalization → **Sim** para nome, health info
- Account management → **Sim** para email, user IDs
- Ad serving → **Não**

**Is this data processed ephemerally?**

Fotos dos scanners IA: **Sim** — nunca persistidas em disco.
Backend recebe base64, encaminha pra Gemini/OpenAI, descarta.
Todo o resto: persistido (com criptografia).

**Is the collection of this data required for your app, or can users choose whether it's collected?**

- Email, User IDs → **Required** (não dá pra logar sem)
- Health info, Fitness info → **Optional** (usuário precisa consentir na 1ª execução e pode revogar)
- App interactions → **Required** (é o core do app)

---

## Section 4 — Security practices

**Is all of the user data collected by your app encrypted in transit?**

→ **Sim**.

**Do you follow the Families Policy?**

→ **Não** (18+, exigimos maioridade legal e prescrição médica).

**Independent security review**

→ Não, mas seguimos padrões HIPAA (encryption at rest AES-256-GCM,
in transit TLS 1.2+, refresh token rotation, reuse detection, lockout
progressivo).

---

## Section 5 — Data deletion

**Provides a way to request that data be deleted**: **Sim**

**Deletion methods**:
- **In-app**: Perfil → Meus Dados → Excluir minha conta
- **Web**: <www.recorpo.com.br/suporte>
- **Email**: `recorpoapp@gmail.com`

**Deletion process**:
- Soft delete imediato (`deleted_at = now()`)
- Email anonimizado para prevenir race conditions
- Refresh tokens revogados
- Purga definitiva 30 dias depois (job periódico no backend)

---

## Perguntas específicas do wizard que costumam pegar

### "Do you use third-party libraries or SDKs that collect data?"

**Sim**:
- **Firebase Auth** (Google Sign-In) — email + user ID Google
- **Google ML Kit** (image labeling on-device) — nenhum dado sai do
  dispositivo, roda 100% local
- **Health Connect** — leitura opt-in de peso, passos, sono, batimentos
- **Google Gemini API** (via nosso backend) — imagens efêmeras
  enviadas quando usuário usa scanner. Nenhum ID nem dado pessoal
  acompanha; imagem é analisada e descartada
- **Sentry** (opcional, só se `SENTRY_DSN` estiver setada) — crash logs
  com PII redigida no cliente antes de enviar

### "Does your app collect health data?"

**Sim, com consentimento explícito**. Modal LGPD na 1ª execução exige
aceite antes de qualquer coleta de saúde. Usuário pode revogar em
Perfil → Meus Dados.

### "Do you share user data with third parties?"

**Sim, com processadores essenciais**:
- Firebase (Google) — auth
- Gemini (Google) — análise efêmera de imagem
- Sentry (opcional) — telemetria de crash anonimizada

**Nunca**:
- Vendemos dados
- Compartilhamos com anunciantes
- Compartilhamos com brokers de dados
- Compartilhamos com outras contas Google Analytics/Ads

### Onde a política de privacidade fica?

→ `https://www.recorpo.com.br/privacidade`
