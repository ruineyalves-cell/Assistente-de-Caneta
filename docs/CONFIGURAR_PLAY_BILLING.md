# Configurar Play Billing (assinatura Premium R$ 19,90)

> Este passo só vale quando o app estiver ao menos em **teste fechado** no Play Console. Antes disso a Play Store não deixa criar produtos.

---

## Pré-requisitos

- [ ] App publicado ao menos em teste fechado (Passos 1 e 2 do PLANO_GOOGLE_PLAY.md)
- [ ] `applicationId` = `br.com.recorpo.app` (já configurado)
- [ ] Você tem conta bancária ligada ao Google Payment Center (Play Console → Payments profile)

---

## Passo 1 — Criar Merchant Account no Play Console

1. Play Console → **Setup** → **Payments profile**
2. Preencha CPF/CNPJ, banco e endereço
3. Aguarde ~2 dias para aprovação (Google confere documento)

Sem esse passo os produtos aparecem "cinza" e ninguém consegue comprar.

---

## Passo 2 — Criar os produtos de assinatura

Play Console → seu app → **Monetize** → **Products** → **Subscriptions**

### Produto 1 — Mensal

- **Product ID:** `recorpo_premium_monthly` *(exatamente esse texto — o app referencia esse ID)*
- **Nome:** Recorpo Premium (Mensal)
- **Descrição:** Acesso completo ao Recorpo com câmera, OCR e PDF ilimitados.
- **Base plan:** `monthly`
- **Preço:** R$ 19,90 por mês
- **Free trial:** 7 dias

### Produto 2 — Anual

- **Product ID:** `recorpo_premium_yearly`
- **Nome:** Recorpo Premium (Anual)
- **Descrição:** Igual ao mensal, com 37% de economia — R$ 12,49/mês cobrados anualmente.
- **Base plan:** `yearly`
- **Preço:** R$ 149,90 por ano
- **Free trial:** 30 dias

**Ativar** ambos — sem clicar em "Active" eles ficam como rascunho e não aparecem no app.

---

## Passo 3 — Testar (Licenced testers)

Play Console → **Setup** → **License testing**

- Adicione seu email Gmail (o mesmo do dispositivo de teste)
- Escolha **"LICENSED"** — te libera comprar sem cartão real (compra em modo sandbox)

Aguarde ~2 horas até a Play Store propagar.

---

## Passo 4 — Testar no app

1. Instale a versão de **teste fechado** (não a de produção)
2. Abra Recorpo → tente uma feature Pro (ex: widget de água) → toca no card "Pro" → cai na Paywall
3. Toque no plano → deve abrir o overlay do Google
4. Confirme → o app deve receber `PurchaseStatus.purchased` e virar Premium

Se receber `PurchaseStatus.error` com `error.code == 'developer_error'`:
- Product ID no Play Console diferente do que está no `premium_service.dart` (checa `kSkuMensal` / `kSkuAnual`)
- App não está assinado com a mesma keystore do upload no Play Console
- Merchant account ainda não aprovado

---

## Como o Recorpo lida com assinatura

- **Grace period:** o Play Store automaticamente dá 3 dias de tolerância se o cartão falhar. O app respeita o status que o Play devolve.
- **Cancelar:** usuário cancela pela **Play Store**, não pelo app. Recorpo detecta via `purchaseStream` na próxima abertura.
- **Restaurar compra:** ao abrir o app numa reinstalação, o `PremiumService.inicializar()` chama `restorePurchases()` automaticamente.
- **Reembolso:** se a Google reembolsar (usuário reclamou em até 48h), o app recebe o evento e volta pra Free.

---

## Estratégia de preço (2026 BR)

R$ 19,90/mês está no mesmo range de:
- Duolingo Super Individual (~R$ 18)
- Cyclebook (~R$ 23)
- Peloton App (~R$ 29)

Anchor psicológico: 1 consulta particular de nutricionista custa R$ 200–350 no Brasil. R$ 149,90/ano = **menos que meia consulta**.

Não dar desconto no primeiro ano — a base precisa aprender que Recorpo é serviço, não app grátis com paywall duro. Trial de 7 dias mensal / 30 dias anual é o suficiente.

---

## O que NÃO fazer

- ❌ **Não** aceitar pagamento fora do Play (Pix direto, Stripe) — viola política Google e pode dar suspensão do app
- ❌ **Não** criar "vitalício" — ninguém compra sem confiar no app; deixa pra oferecer no ano 2 se tiver base
- ❌ **Não** cobrar mais barato em introdução — depois é impossível subir sem revolta
