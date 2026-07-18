# Ativar IA de reconhecimento de refeição

> **Custo:** R$ 0 se usar Gemini 1.5 Flash (o free tier do Google AI Studio cobre milhares de imagens/mês). Cerca de US$ 0,01 por foto se usar OpenAI gpt-4o-mini.
>
> **Sem essas chaves, o app ainda funciona** — cai no reconhecimento local do Google ML Kit (grátis, on-device), que identifica "Comida / Fruta / Carne / Salada" com confiança. Basta.

---

## Opção A — Gemini (recomendado, grátis)

### 1. Gerar chave

1. Vá em https://aistudio.google.com/apikey
2. Login com a mesma conta Google que administra o app
3. Clique em **"Create API key"** → escolha o mesmo projeto Firebase do login
4. Copie a chave (começa com `AIza...`)

### 2. Configurar no Render

1. Painel do Render → serviço `assistente-caneta-backend` → **Environment**
2. **Add Environment Variable**
3. Nome: `GEMINI_API_KEY`
4. Valor: cole a chave
5. Save → Render redeploya

### 3. Testar

- Instale o app novo (CI cuida do APK)
- Vá em Home → **Refeição** → tire uma foto
- Depois da câmera, deve aparecer o card **"Análise IA detalhada"** com título e proteína estimada

---

## Opção B — OpenAI (pago, mais acurado em pratos brasileiros)

### 1. Gerar chave

1. https://platform.openai.com/api-keys
2. Adicione ~US$5 de crédito (dá pra ~500 fotos com gpt-4o-mini)
3. **Create new secret key** → copie (começa com `sk-...`)

### 2. Configurar no Render

Mesmo passo do Gemini, com nome `OPENAI_API_KEY`.

⚠️ Se **as duas** chaves estiverem configuradas, o backend usa a Gemini (prioridade grátis).

---

## Como o app se comporta em cada cenário

| Chave IA no backend | Card local | Card IA detalhada |
|---|---|---|
| Nenhuma | ✅ Roda (labels: comida, fruta…) | ❌ "IA detalhada ainda não ativada" |
| Gemini | ✅ | ✅ Título + proteína + água |
| OpenAI | ✅ | ✅ Título + proteína + água |
| Ambas | ✅ | ✅ (via Gemini, prioridade grátis) |

---

## Custos reais (2026-07)

**Gemini 1.5 Flash (recomendado):**
- Free tier: 1.500 requests/dia = 45.000 fotos/mês
- Pago (se ultrapassar): ~US$ 0,000075 por foto

**OpenAI gpt-4o-mini:**
- ~US$ 0,01 por foto (imagem + resposta curta)
- 100 fotos/dia = ~US$ 30/mês
- Vale se o Gemini começar a errar muito em pratos regionais

---

## Onde a foto vai parar

- **Reconhecimento local:** foto **nunca sai do celular**. Processada 100% on-device pelo Google ML Kit.
- **Análise backend:** foto vai em `POST /api/ia/refeicao` como base64 → backend chama Gemini/OpenAI → resposta volta → **foto não é persistida** (nem no disco do Render nem no PostgreSQL).
- **Contrato LGPD respeitado:** endpoint marcado como `audit('read', 'ia_refeicao')` no `routes/index.js` — cada análise gera registro no `access_log`.
