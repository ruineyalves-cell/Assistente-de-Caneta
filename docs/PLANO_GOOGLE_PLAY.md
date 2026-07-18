# Recorpo — Plano de publicação Google Play (Brasil 2026)

> **Objetivo:** publicar o app na Play Store BR gastando quase nada e chegar a 20 assinantes pagantes em 12 semanas.
> **Autor:** consolidado em 2026-07-18 a partir de conversa com o usuário.
> **Fonte de referência:** este arquivo é o plano oficial. Alterações voltam a passar por revisão.

---

## Glossário mínimo (siglas que aparecem nesta pasta)

| Sigla | Tradução prática |
|---|---|
| **Play Console** | Painel da Google onde se publica app na Play Store |
| **AAB** | Arquivo assinado que a Play Store exige (o `.apk` continua servindo para instalação lateral) |
| **Play Billing** | Sistema de pagamento nativo da Google dentro do app; Google fica com 15% em assinaturas |
| **MAU** | Usuários ativos por mês |
| **D7 / D30** | Retenção no dia 7 e no dia 30 após instalação |
| **CAC** | Custo para conquistar 1 usuário pagante |
| **LTV** | Receita que 1 usuário gera ao longo do tempo no app |
| **MRR / ARR** | Receita mensal / anual recorrente |
| **LGPD** | Lei brasileira de proteção de dados |
| **DPO** | Responsável pela LGPD (pode ser o próprio dono no começo) |
| **Anvisa** | Regula produto de saúde. **Recorpo hoje é app educacional, fora do escopo dela** |
| **B2C / B2B / B2B2C** | Quem paga: paciente / empresa / empresa que revende ao paciente |
| **INPI** | Registro de marca no Brasil |
| **Firebase** | Backend gerenciado da Google usado aqui para o login social |
| **OAuth** | Protocolo para "entrar com Google/Apple/Facebook" |

---

## Situação atual (o que já existe)

- ✅ Conta Play Console paga (US$25 vitalícios — pago uma vez)
- ✅ App Flutter funcional, testado no Galaxy S25
- ✅ Backend Node.js/Express no Render (grátis; primeira request pode demorar ~60s)
- ✅ Login por email/senha funcionando
- ✅ Notificações locais com nome do usuário (awesome_notifications)
- ✅ Widgets Android (refeição + água)
- ✅ Câmera + OCR de prescrição + PDF pro médico
- ✅ Dashboard, streak, macros, ajuste de esforço, gráfico
- ✅ CI GitHub Actions gerando APK/AAB em cada push

---

## Cronograma resumido (12 semanas)

| Semana | Foco | Custo | Meta |
|---|---|---|---|
| 1–2 | Preparação técnica: ícone, screenshots, applicationId, keystore | R$ 0 | AAB assinado pronto |
| 3–4 | Teste fechado com 20 pessoas conhecidas | R$ 0 | 10–15 feedbacks reais |
| 5–6 | Teste aberto (Beta público) | R$ 0 | 200–500 instalações |
| 7–8 | Corrigir bugs prioritários + implementar Play Billing | R$ 0 | Fluxo de assinatura pronto |
| 9–10 | Publicar em Produção + ativar Premium R$ 19,90 | R$ 0 | App público na Play Store BR |
| 11–12 | Marketing orgânico diário (Instagram + WhatsApp + grupos) | R$ 0 | 20 assinantes pagantes = R$ 400 MRR |

**Investimento total previsto**: R$ 0 (US$25 já pagos anteriormente no Play Console).

---

## Fase 1 — Preparação técnica (semanas 1 e 2)

### 1.1. Configurações obrigatórias antes de publicar

- [ ] Trocar `applicationId` de `com.example.assistente_caneta` para `br.com.recorpo.app` em `android/app/build.gradle.kts`
- [ ] Gerar release keystore própria (comando único; **backup obrigatório na nuvem privada** — se perder, nunca mais atualiza o app)
- [ ] Configurar GitHub Actions para assinar o AAB com a keystore (secrets: `RECORPO_KEYSTORE_BASE64`, `RECORPO_KEYSTORE_PASSWORD`, `RECORPO_KEY_ALIAS`, `RECORPO_KEY_PASSWORD`)
- [ ] Página de política de privacidade em URL público (GitHub Pages grátis) — apontar do Play Console e da tela de disclaimer
- [ ] Página de termos de uso em URL público (mesmo repositório)
- [ ] Ícone Recorpo 512×512 (Canva grátis, azul clínico #2B6CB0)
- [ ] Ícone adaptativo Android (foreground + background separados)
- [ ] Feature graphic 1024×500 para vitrine da Play Store
- [ ] 4 a 8 screenshots 1080×1920 mostrando: Home, PDF do médico, Câmera de refeição, Widget de água

### 1.2. Metadados da vitrine

- **Nome curto**: `Recorpo` (7 caracteres, sobra espaço)
- **Nome longo (30 chars)**: `Recorpo — Ozempic e GLP-1`
- **Descrição curta (80 chars)**: `Acompanhe seu tratamento com Ozempic, Mounjaro e outros GLP-1 no Brasil.`
- **Descrição longa (4000 chars)**: rascunho abaixo, revisar com quem fez tratamento

```
Recorpo é o assistente diário de quem toma GLP-1 (Ozempic, Mounjaro,
Wegovy, Saxenda, Rybelsus). Feito no Brasil, em português, sem
substituir seu médico.

O QUE O RECORPO FAZ POR VOCÊ:
• Registro rápido de peso, proteína e água (menos de 30 segundos)
• Streak de consistência — igual as academias que motivam quem vai
• Widget na tela inicial para bater sua meta de água sem abrir o app
• Câmera de refeição: fotografe o prato e o app registra pra você
• Leitura automática de prescrição nutricional (OCR)
• Relatório PDF pronto pra levar na consulta
• Notificações acolhedoras, com seu nome, no tom certo
• Integração com Health Connect (passos, peso, batimentos)

VERSÃO PREMIUM (R$ 19,90/mês ou R$ 149,90/ano):
• Câmera e OCR ilimitados
• PDF pro médico com histórico completo
• Widget de água silencioso na tela
• Comparativos históricos 30/60/90 dias
• Sem anúncios

PRIVACIDADE (LGPD):
Seus dados de saúde ficam com você. Você pode exportar tudo em JSON
ou excluir sua conta a qualquer momento, direto no app.

AVISO:
Recorpo não é dispositivo médico e não substitui acompanhamento
profissional. Sempre siga a prescrição do seu médico.
```

### 1.3. Palavras-chave para a Play Store (ASO)

Ordem de importância:
1. `ozempic`
2. `mounjaro`
3. `glp-1`
4. `emagrecimento medicamento`
5. `saxenda wegovy`
6. `contador proteina`
7. `hidratação`
8. `assistente diabetes`

---

## Fase 2 — Teste fechado (semanas 3 e 4)

### 2.1. Testadores-alvo (15–20 pessoas)

- 5 pessoas próximas que estão em tratamento GLP-1 hoje
- 3 endocrinologistas conhecidos (mesmo que amigo de amigo)
- 2 nutricionistas
- 5–10 amigos ou familiares para catar bugs de uso comum

### 2.2. Coleta de feedback

- Grupo dedicado no WhatsApp: "Recorpo Beta Fechado"
- Formulário Google Forms de 5 perguntas ao fim de cada semana
- Prioridade de correção: crashes > confusão de fluxo > pedidos de feature nova

### 2.3. Critério de saída

- Zero crashes reportados na última semana
- Pelo menos 10 dos 20 testadores ativos no dia 7
- 3 fixes prioritários aplicados

---

## Fase 3 — Teste aberto (semanas 5 e 6)

### 3.1. Divulgação orgânica (R$ 0)

- **WhatsApp**: 1 grupo por semana em comunidades de pacientes GLP-1 (regra: conteúdo útil primeiro, menção ao app no final)
- **Instagram @recorpo.app**: 3 posts por semana (dicas de blindagem muscular, mitos, receitas proteicas)
- **Reels de 30s**: 2 por semana (Instagram + TikTok)
- **Parceria com 2 nutricionistas**: 3 meses Premium grátis para pacientes deles em troca de indicação

### 3.2. Meta

- 200–500 instalações em 30 dias
- Retenção D7 > 30%
- Retenção D30 > 15%

---

## Fase 4 — Produção + Monetização (semanas 7 a 10)

### 4.1. Play Billing (assinatura Premium)

- Criar SKU no Play Console:
  - `recorpo_premium_monthly` — R$ 19,90/mês
  - `recorpo_premium_yearly` — R$ 149,90/ano (economia 37%)
- Trial de 7 dias grátis para monthly
- Trial de 30 dias grátis para yearly

### 4.2. O que vai no Free vs no Premium

| Feature | Free | Premium |
|---|---|---|
| Dashboard, streak, score, gráfico | ✅ | ✅ |
| Registro manual de peso/proteína/água | ✅ | ✅ |
| Câmera de refeição | 1×/dia | Ilimitado |
| OCR de prescrição | 1×/semana | Ilimitado |
| Widget de refeição | ✅ | ✅ |
| Widget de água silencioso | ❌ | ✅ |
| PDF pro médico | 1×/mês | Ilimitado |
| Notificações personalizadas + celebrações | Básico | Completo |
| Health Connect / integração relógio | ✅ | ✅ |
| Comparativos históricos 30/60/90 dias | 30 dias | 30/60/90 |
| Ajuste de esforço detalhado | Básico | Completo |
| Anúncios (adicionar após 500 usuários) | Sim | Não |

### 4.3. Preço e ponto de referência (Brasil 2026)

- R$ 19,90/mês é o mesmo range de Duolingo Super, Cyclebook, Peloton BR
- R$ 149,90/ano equivale a R$ 12,49/mês
- Anchor psicológico: 1 consulta de nutricionista particular custa 3× isso

---

## Fase 5 — Marketing orgânico contínuo (semana 11 em diante)

### 5.1. Instagram / TikTok

- 1 Reel por dia (30s max)
- Temas rotativos:
  - Segunda: mito x verdade sobre GLP-1
  - Terça: receita proteica rápida
  - Quarta: dica de hidratação
  - Quinta: caso de sucesso (com autorização por escrito)
  - Sexta: bastidor / feature nova do app
  - Sábado: FAQ (uma pergunta por semana)
  - Domingo: reflexão / motivação

### 5.2. WhatsApp

- Comunidade "Recorpo — Suporte" (canal público)
- Grupo VIP para assinantes Premium

### 5.3. Parcerias

- Meta: 1 novo nutricionista ou endocrinologista parceiro por mês
- Comissão de indicação: 20% da primeira anuidade (paga em Pix)

---

## Fase 6 — Escala (mês 4 em diante, apenas se atingir 20 pagantes)

- Adicionar Meta Ads: R$ 15/dia focado em interesse "Ozempic Brasil"
- Adicionar Google Ads Search: R$ 10/dia em keywords "app ozempic"
- Contratar 1 nutricionista freelancer para criar conteúdo (R$ 800/mês)
- Migrar Render free para pago (US$7/mês) quando MAU > 500

---

## O que NÃO fazer nos primeiros 6 meses

- ❌ Abrir CNPJ antes de faturar > R$ 8k/mês (recebe como pessoa física via Stripe/Play até lá)
- ❌ Registrar marca via advogado (INPI direto pelo site custa ~R$ 400)
- ❌ Advogado revisando termos (só quando faturar > R$ 20k/mês ou negociar com clínica)
- ❌ Render pago (o retry automático 5xx cobre a hibernação)
- ❌ Portal do médico web (só quando 3 clínicas disserem "compraria se tivesse")
- ❌ Anúncios pagos antes de retenção D30 > 20%

---

## Features paralelas em desenvolvimento (autorização expressa 2026-07-18)

### Lote 20 — Login social (Google/Apple)
Adicionar botão "Entrar com Google" na tela de login usando `google_sign_in`. Requer:
- Projeto Firebase criado pelo usuário
- `google-services.json` colocado em `android/app/`
- OAuth Client ID configurado no console Google Cloud

### Lote 21 — IA de refeição
Reconhecimento de comida na foto. Duas rotas em paralelo:
- **Local (sem custo)**: `google_mlkit_image_labeling` — identifica "food", "salad", "meat" etc.
- **Backend (opcional)**: rota `POST /api/ia/refeicao` que aceita chave OpenAI/Gemini quando o usuário configurar, para descrição detalhada e estimativa de proteína

### Lote 22 — Health Connect real
Completar `health_connect_service.dart` para ler passos, peso e batimentos via package `health^13` e alimentar o `HealthHubScreen` com dados reais.

### Lote 23 — Play Billing (Premium)
Package `in_app_purchase`, `PremiumProvider`, `FeatureGate`. Requer usuário criar SKUs no Play Console:
- `recorpo_premium_monthly` R$ 19,90
- `recorpo_premium_yearly` R$ 149,90

---

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Google recusa app na revisão (categoria "medical") | Deixar bem claro nos textos: "app educacional, não é dispositivo médico" |
| Concorrente maior copia | Vantagem = comunidade + relacionamento com pacientes GLP-1 BR |
| Anvisa muda escopo do que é "SaMD" | Ficar em app educacional até haver receita para justificar advogado |
| Render cai em pico | Retry 5xx no Dio + migrar para Render pago quando MAU > 500 |
| Play Console suspende conta | Backup local do AAB + keystore + código-fonte no GitHub |
| Perda da keystore | Copiar em 3 locais separados: cofre local, 1Password, cofre físico |

---

## Sinais para acelerar (gates de decisão)

- **Se em 6 semanas < 100 instalações**: revisar ASO da vitrine e conteúdo do Instagram
- **Se em 3 meses < 20 pagantes**: revisar preço ou re-embalar features
- **Se em 6 meses > 200 pagantes (R$ 4k MRR)**: começar a estudar CNPJ e contador
- **Se em 12 meses > 1.000 pagantes (R$ 20k MRR)**: buscar primeira parceria com clínica
