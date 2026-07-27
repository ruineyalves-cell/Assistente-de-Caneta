# Play Billing — setup do backend

Guia pra ligar a validação server-side de assinaturas Premium com o
Google Play Android Publisher API.

**Pré-requisito:** app publicado (mesmo em teste interno) e no mínimo
uma assinatura criada no Play Console → Monetize → Products →
Subscriptions.

O código do backend já está pronto e commitado:
- Migration `database/migrations/004_subscriptions.sql`
- `backend/src/utils/playApi.js` — cliente HTTP autenticado
- `backend/src/controllers/subscriptionController.js` — 3 endpoints
- Rate limit dedicado (`subscriptionLimiter`) em rateLimiter.js
- Testes: `backend/tests/subscriptionController.test.js` e `playApi.test.js`
  (25 casos)

Só falta você criar a service account, dar permissão no Play e colar
o JSON no Render. **~15 min manuais.**

---

## Passo 1 — Criar service account no Google Cloud

1. Abra o projeto Google Cloud que vai integrar com o Play.
   - Se ainda não tem, crie um novo em https://console.cloud.google.com/
     (Firebase e OAuth podem ser no mesmo).
2. Menu ☰ → IAM & Admin → **Service Accounts** → **Create service account**.
3. Nome: `play-billing-server`
4. **Não** dê nenhum "role" nesta tela (o Play Console concede
   permissão separadamente — evita over-provisioning).
5. Clique em **Done**.
6. Na lista, abra a service account criada → aba **Keys** → **Add key** →
   **Create new key** → JSON. Vai baixar um arquivo `.json`.

**Segurança:** esse arquivo é a chave de acesso. Não commite, não
compartilhe. Só ele + a env var no Render.

## Passo 2 — Ativar a Android Publisher API

Ainda no mesmo projeto GCP:

1. Menu ☰ → APIs & Services → **Library**.
2. Busque "Google Play Android Developer API" → **Enable**.

Sem isso, a API responde 403 mesmo com service account válida.

## Passo 3 — Autorizar a service account no Play Console

1. Abra https://play.google.com/console.
2. **Users and permissions** (menu esquerdo) → **Invite new users**.
3. Email: cole o email da service account (formato
   `play-billing-server@<projeto>.iam.gserviceaccount.com` —
   está dentro do JSON, campo `client_email`).
4. **App permissions** → adicione o app **Recorpo** → dê:
   - ✅ **View financial data, orders, and cancellation survey responses**
   - ✅ **Manage orders and subscriptions**
5. **Invite user**. Ela aceita automaticamente (é uma service account).

**Propagação:** o Play leva até 24h pra aplicar as permissões — na
prática costuma ser <5 min.

## Passo 4 — Configurar as envs no Render

No serviço `assistente-caneta-backend-tkl7` → Environment → adicione:

| Chave | Valor |
|---|---|
| `GOOGLE_PLAY_PACKAGE_NAME` | `br.com.recorpo.app` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | **base64** do JSON baixado no passo 1 |

Pra gerar o base64:

```bash
# Linux / macOS / Git Bash
base64 -w0 caminho/do/service-account.json

# PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("caminho\service-account.json"))
```

Cole a saída inteira no valor da env var (é uma linha só, longa).

Save Changes → redeploy automático.

**Opcional** (recomendo depois de ter Pub/Sub configurado, passo 6):

| Chave | Valor |
|---|---|
| `RTDN_SHARED_SECRET` | 32+ chars aleatórios (gera com `node -e "console.log(require('crypto').randomBytes(24).toString('base64url'))"`) |

## Passo 5 — Testar

Depois do redeploy, com um APK que já contenha o Play Billing Library
integrado:

1. Compre uma assinatura em teste interno (Play trata compras de
   testers como test purchases — sem cobrança real).
2. App chama `POST /api/assinaturas/validar` com `{ purchaseToken, productId }`.
3. Espera resposta `{ premium: true, status: "active", expiryTime, ... }`.

Sem app pronto pra testar? Faça o smoke via curl direto (precisa de
JWT do backend):

```bash
curl -X POST https://assistente-caneta-backend-tkl7.onrender.com/api/assinaturas/validar \
  -H "Authorization: Bearer <seu_jwt>" \
  -H "Content-Type: application/json" \
  -d '{"purchaseToken":"tok_falso","productId":"premium_mensal"}'
```

Se estiver tudo ok, você recebe 404 com mensagem
"Compra não reconhecida pelo Google Play" — significa que o backend
achou as credenciais, chamou a Play API, e o Play devolveu 404 (o
token é fake). Se receber 503, o env `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
está ausente. Se 500, veja logs no Render — provavelmente permissão
ainda não propagou.

## Passo 6 (opcional, mas recomendado) — RTDN via Pub/Sub

Assinaturas mudam de estado (renovação, cancelamento, refund, grace
period) mesmo sem o app estar aberto. Sem RTDN, o cache local pode
ficar até 12h desatualizado.

1. GCP → Pub/Sub → **Topics** → **Create topic**.
   Nome: `play-billing-rtdn-recorpo`.
2. Play Console → seu app → Monetize → **Monetization setup** →
   **Real-time developer notifications** → cole o topic name
   `projects/<seu-projeto>/topics/play-billing-rtdn-recorpo` →
   **Save**.
3. GCP → Pub/Sub → **Subscriptions** → **Create subscription**.
   - Topic: `play-billing-rtdn-recorpo`
   - Delivery type: **Push**
   - Endpoint URL: `https://assistente-caneta-backend-tkl7.onrender.com/api/assinaturas/rtdn`
   - Push authentication: **Enable** + escolha uma service account
   - Add header: `x-rtdn-secret: <mesmo valor de RTDN_SHARED_SECRET>`
4. **Send test notification** no Play Console pra confirmar.

Endpoint sempre responde 200 (mesmo em erro) pra evitar retry
agressivo do Pub/Sub. Erros ficam nos logs.

---

## Custos e limites

- **Play API**: 200 000 queries/dia (grátis). Nunca chegamos perto —
  cada usuário faz no máximo ~5 chamadas/mês.
- **Pub/Sub push**: primeiros 10 GB/mês grátis. RTDN é kilobytes.
- **Service account key**: sem custo.

## O que o código faz automaticamente

- **Acknowledge** em <=3 dias (Play refunda se você não fizer).
- **Cache local** com re-check quando >12h.
- **Fail-closed** em erro: `_isPremium` só devolve true pra estados
  `active` ou `grace_period` com `expiryTime` no futuro.
- **Rate limit** 20 req/min por usuário no `/validar`.

## Rotação de credencial

Se a service account key for exposta:

1. GCP → Service Accounts → aba Keys → delete a chave comprometida.
2. Gere nova key JSON (mesmo processo do passo 1).
3. Atualize `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` no Render com o novo
   base64. Redeploy automático — zero downtime, pool de conexões da
   Play API renova.
