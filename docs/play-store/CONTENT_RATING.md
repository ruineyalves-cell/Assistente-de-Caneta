# Google Play — Content Rating (IARC)

Respostas pré-preenchidas para o questionário **Content Rating** (Play
Console → App content → Content ratings). O IARC é um sistema global
— responder essas perguntas gera as classificações **ClassInd (Brasil)**,
**ESRB (América)**, **PEGI (Europa)**, etc.

**Categoria recomendada**: **Utility, Productivity, Communication, or Other**
→ subcategoria **Health & Fitness**.

Isso muda o questionário — Health & Fitness não recebe perguntas de
violência/sexo/apostas, só de "medical information".

---

## Antes de começar

1. Play Console → All apps → Recorpo → App content
2. Content ratings → Start questionnaire
3. Email: `recorpoapp@gmail.com`
4. Category: **Utility, Productivity, Communication, or Other**

---

## Respostas

### Violence
- Cartoon or fantasy violence: **No**
- Realistic violence: **No**
- Blood: **No**
- Sexual violence or aggression: **No**

### Sexuality
- Nudity: **No**
- Sexual content or references: **No**

### Language
- Profanity or crude humor: **No**

### Controlled substance
- References to or depictions of tobacco, alcohol, or drugs: **No**
  → **Justificativa**: o app registra uso de medicação prescrita
  (GLP-1: Ozempic, Mounjaro, Wegovy, Saxenda), o que **não** conta
  como "drug reference" pelo IARC — é medicamento sob prescrição
  médica. A pergunta se refere a substâncias recreacionais/ilícitas.

### Gambling
- Simulated gambling: **No**
- Real money gambling: **No**

### Miscellaneous
- Encourages or facilitates illegal activities: **No**
- Encourages discrimination or hate: **No**
- User-generated content shared with others: **No**
  → **Justificativa**: notas do usuário ficam privadas por padrão.
  O único compartilhamento é o **PDF** que o próprio usuário decide
  levar ao médico — não é publicação pública.
- Users can interact or exchange content: **No**
  → Portal médico é 1:1 (paciente ↔ profissional vinculado
  explicitamente), não é feed social nem chat público.

### Data collection and sharing (mesmas respostas do Data Safety)
- Shares user data with third parties: **Yes** (Firebase, Gemini,
  Sentry — todos como processadores essenciais)
- Collects personal information: **Yes** (email, nome, dados de saúde)

### Location sharing
- Shares user location: **No**

### Digital purchases
- Users can purchase digital goods: **Yes**
  → Assinatura Premium via Play Billing. Mensal e anual.

---

## Classificação esperada

Com as respostas acima:

| Sistema | Rating |
|---|---|
| **ClassInd (Brasil)** | **L (Livre)** |
| IARC Global | **3+** |
| ESRB | **Everyone** |
| PEGI | **3** |

> ⚠️ Se o Play Console classificar como **12+** ou mais restrito,
> revise as respostas de "controlled substance" — GLP-1 pode ser
> mal-interpretado. Justifique via email de contestação
> (`play-console-help`) que é uso terapêutico sob prescrição,
> não referência a droga.

---

## Depois de submeter

1. Save
2. A classificação é aplicada em 1-2 minutos.
3. Aparece no listing da Play Store como "Livre para todos os públicos".
