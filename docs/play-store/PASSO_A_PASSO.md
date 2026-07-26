# Play Console — Passo a passo das 5 declarações restantes

Documento pra você preencher sozinho no Play Console, sem precisar consultar mais nada.
Cada seção diz **o que clicar** + **o texto exato pra colar**. Ordem otimizada: as 3 rápidas primeiro.

**Estado inicial**: acesse
`https://play.google.com/console/u/1/developers/9115750489429426247/app/4972194763234982924/app-content/overview`

Deve mostrar **"5 declarações precisam de atenção"** (as 5 abaixo, na ordem em que aparecem).

---

## ⚡ 1. Apps governamentais (30s)

**Contexto**: Recorpo é app de consumidor final, não é ferramenta de governo.

1. No card **"Apps governamentais"** → clique **"Iniciar declaração"**
2. Marque radio: **"Não, esta app não é uma app governamental"**
3. Clique **"Guardar"**
4. Espera aparecer *"Alteração guardada"* em verde no rodapé
5. Volte pro overview: clique em **"Conteúdo da app"** na navegação lateral (ou seta pra trás)

---

## ⚡ 2. Funcionalidades financeiras (2 min)

**Contexto**: você vai cobrar Play Billing (SKUs Premium). Tem que declarar transações in-app.

1. Card **"Funcionalidades financeiras"** → **"Iniciar declaração"**

2. Vai perguntar: *"A sua app oferece alguma das seguintes funcionalidades financeiras?"*
   - ✅ Marque **"Aceita transações no app"** (pagamentos via Play Billing)
   - ❌ Deixe TODAS as outras desmarcadas:
     - ~~Serviços financeiros pessoais~~ (bancos, fintechs)
     - ~~Empréstimos~~
     - ~~Criptomoedas~~
     - ~~Câmbio~~
     - ~~Corretagem~~
     - ~~Seguros~~
     - ~~Regulamentado por governo~~

3. Se pedir detalhes sobre "transações no app":
   - **Tipo de conteúdo pago**: "Serviço digital" (assinatura de recursos Premium do app)
   - **Método de pagamento**: "Sistema de faturação do Google Play" (obrigatório pra apps não-financeiros)

4. **"Guardar"**

---

## ⚡ 3. Apps de saúde (5 min)

**Contexto**: declaração sensível, Google faz review humano. Marque exatamente conforme abaixo.

1. Card **"Apps de saúde"** → **"Iniciar declaração"**

2. Vai perguntar se sua app tem algum dos itens (marque **SIM** apenas nos abaixo):

   **✅ Marcar (temos)**:
   - **Coleta ou processa dados de saúde/fitness do usuário**
     - Sub-pergunta: *quais categorias de dados?*
       - ✅ Peso / IMC
       - ✅ Nutrição / hidratação
       - ✅ Sintomas
       - ✅ Frequência cardíaca (Health Connect)
       - ✅ Passos / atividade física (Health Connect)
       - ✅ Sono (Health Connect)
       - ✅ Medicação (uso de GLP-1)
   - **Integração com Health Connect API** (Android)
   - **Ferramentas de acompanhamento/rastreamento** (dashboard, resumo diário)
   - **Recorda o usuário de tomar medicamento** (notificações de dose)

   **❌ NÃO marcar (não temos)**:
   - ~~Fornece diagnóstico médico~~
   - ~~Fornece prescrição médica~~
   - ~~Realiza consulta médica remota (telemedicina)~~
   - ~~Envia dados a profissional de saúde SEM consentimento explícito~~ (nosso portal médico exige vínculo aceito)
   - ~~É dispositivo médico regulamentado (SaMD Anvisa Classe II ou superior)~~
   - ~~Testa/mede sinais vitais via câmera/sensores do celular~~
   - ~~Fornece serviços de saúde mental críticos (crise, suicídio)~~

3. Se pedir **URL da política de privacidade específica pra saúde**:
   - Cole: `https://www.recorpo.com.br/privacidade`

4. Se pedir **descrição da finalidade**:
   ```
   O Recorpo é uma ferramenta educacional de registro para pessoas em tratamento com medicamentos GLP-1 (Ozempic, Mounjaro, Wegovy, Saxenda). Permite ao usuário registrar peso, hidratação, refeições, sintomas e adesão à medicação, gerando um relatório em PDF para consulta com o próprio médico. Não fornece diagnóstico, prescrição ou substitui orientação médica.
   ```

5. **"Guardar"**

---

## 📋 4. Classificações de conteúdo — IARC (10 min)

**Contexto**: questionário longo (~20 perguntas) que gera classificação etária oficial (ClassInd/ESRB/PEGI).
Todas as respostas já estão em [CONTENT_RATING.md](CONTENT_RATING.md). Segue o resumo prático:

1. Card **"Classificações de conteúdo"** → **"Iniciar questionário"**

2. Tela **"Início"**:
   - **Email de contato**: `recorpoapp@gmail.com`
   - **Categoria**: **"Utility, Productivity, Communication, or Other"**
   - Clique **"Seguinte"**

3. Tela **"Violência"** — marque **"Não"** em todas:
   - Violência cartoon/fantasia: **Não**
   - Violência realista: **Não**
   - Sangue: **Não**
   - Violência sexual: **Não**

4. Tela **"Sexualidade"** — marque **"Não"** em todas:
   - Nudez: **Não**
   - Conteúdo sexual: **Não**

5. Tela **"Linguagem"**:
   - Profanidade: **Não**

6. Tela **"Substâncias controladas"**:
   - Referências a tabaco, álcool ou drogas: **Não**

   > ⚠️ **Importante**: se pedir justificativa, marque "Não". Medicamentos GLP-1 sob prescrição médica **não** contam como referência a droga pelo IARC. Se algum dia der 12+ por engano, contesta via botão "Recurso" citando: *uso terapêutico sob prescrição, não referência recreacional*.

7. Tela **"Jogos de azar"**:
   - Simulado: **Não**
   - Real: **Não**

8. Tela **"Diversos"**:
   - Encoraja atividades ilegais: **Não**
   - Discriminação/ódio: **Não**
   - **Conteúdo gerado pelo usuário compartilhado publicamente**: **Não**
     - (Notas do usuário são privadas; PDF só o usuário escolhe compartilhar)
   - **Usuários podem interagir/trocar conteúdo**: **Não**
     - (Portal médico é 1:1 vinculado; não é feed social)

9. Tela **"Coleta e compartilhamento de dados"**:
   - **Compartilha dados com terceiros**: **Sim** (Firebase, Gemini, Sentry — processadores essenciais)
   - **Coleta informações pessoais**: **Sim** (email, nome, saúde)

10. Tela **"Localização"**:
    - Compartilha localização: **Não**

11. Tela **"Compras digitais"**:
    - Usuários podem comprar bens digitais: **Sim** (assinatura Premium via Play Billing)

12. **"Guardar"** → **"Aplicar classificação"**

**Resultado esperado**: **ClassInd Livre / IARC 3+ / ESRB Everyone / PEGI 3**. Se der maior, revise as respostas de "substâncias".

---

## 🛡️ 5. Segurança dos dados — Data Safety (15 min)

**Contexto**: o mais longo e mais crítico. Google usa isso pra mostrar labels de privacidade na Play Store.
Todas as respostas mapeadas 1:1 em [DATA_SAFETY.md](DATA_SAFETY.md). Segue o passo a passo:

### Tela 1 — Coleta e segurança
1. Card **"Segurança dos dados"** → **"Iniciar declaração"**
2. **"A app coleta ou compartilha dados do usuário?"** → **Sim**
3. **"Todos os dados são criptografados em trânsito?"** → **Sim**
4. **"Você fornece uma forma para os usuários solicitarem exclusão de dados?"** → **Sim**

### Tela 2 — Tipos de dados coletados

Marque nas categorias abaixo. Pra CADA um marcado, o wizard pede: *coletado? compartilhado? opcional? finalidade?*

#### 👤 Informações pessoais
| Campo | Coletado? | Comp.? | Opcional? | Finalidade |
|---|---|---|---|---|
| Nome | Sim | Não | Sim | Personalização da conta |
| Endereço de e-mail | Sim | Não | Não | Login + comunicação essencial |
| IDs de usuário | Sim | Não | Não | Autenticação (JWT interno) |

Deixe **desmarcados**: Endereço postal, Telefone, Raça/etnia, Orientação política, Orientação sexual, Nível educação, Local de trabalho, Documento de identidade, Extrato bancário.

#### 💰 Informações financeiras
- ✅ **Histórico de compras** — Coletado: Sim / Compartilhado: Não / Opcional: Não / Finalidade: **Funcionalidade do app**
- ❌ Desmarcar: Cartão de crédito, Info financeira do usuário, Outras info financeiras

#### 🏥 Saúde e fitness
- ✅ **Informações de saúde** (peso, IMC, hidratação, refeições, sintomas, medicação)
  - Coletado: Sim / Compartilhado: Não / Opcional: Sim / Finalidade: **Funcionalidade do app**
- ✅ **Informações de fitness** (passos, calorias ativas, sono via Health Connect)
  - Coletado: Sim / Compartilhado: Não / Opcional: Sim / Finalidade: **Funcionalidade do app**

#### 💬 Mensagens
Deixe TUDO desmarcado (E-mails, SMS, Outras mensagens).

#### 📸 Fotos e vídeos
- ✅ **Fotos** — Coletado: **Sim (efêmero)** / Compartilhado: **Sim, com Google (Gemini API)** / Opcional: **Sim** (usuário decide quando usar scanner) / Finalidade: **Funcionalidade do app (análise IA)**

**⚠️ Importante**: no wizard, ao marcar "compartilhado com terceiros", vai pedir descrição. Cole:
```
Imagens capturadas pelos scanners de refeição/rótulo/bula são enviadas à Gemini API do Google exclusivamente para análise em tempo real. Não são armazenadas em nossos servidores nem retidas pela Google. Uso é opt-in por scanner.
```

#### 🎵 Arquivos de áudio
Deixe TUDO desmarcado.

#### 📁 Arquivos e documentos
Deixe TUDO desmarcado.

#### 📅 Calendário, Contatos
Deixe TUDO desmarcado.

#### 🎯 App activity
- ✅ **Interações com o app** (registros diários, uso de scanners)
  - Coletado: Sim / Compartilhado: Não / Opcional: Não / Finalidade: **Funcionalidade do app** + **Análise (interna, agregada)**

Deixe desmarcado: Histórico de busca no app, Apps instalados, Outras ações do usuário.

#### 🌐 Info de navegação web
Deixe TUDO desmarcado.

#### 📱 Informações do app e desempenho
- ✅ **Logs de falha** — Coletado: **Sim** (se `SENTRY_DSN` estiver configurado) / Compartilhado: **Sim, com Sentry** / Opcional: Não / Finalidade: **Análise** + **Correção de bugs**
- ✅ **Diagnósticos** (métricas de latência) — Coletado: Sim / Compartilhado: Não / Opcional: Não / Finalidade: **Análise**

#### 🆔 Device or other IDs
Deixe TUDO desmarcado (**NÃO** coletamos advertising ID).

### Tela 3 — Práticas de segurança
1. **Todos os dados são criptografados em trânsito?** → **Sim**
2. **Segue a Families Policy?** → **Não** (app é 18+)
3. **Passou por revisão de segurança independente?** → **Não**

### Tela 4 — Exclusão de dados
1. **Fornece forma de solicitar exclusão?** → **Sim**
2. **Como o usuário exclui os dados?** → cole:
   ```
   Dentro do app: Perfil → Meus Dados → Excluir minha conta. Confirmação dupla exige digitar "EXCLUIR". Alternativa por e-mail: recorpoapp@gmail.com. Soft delete imediato + purga definitiva em 30 dias (LGPD art. 18 VI).
   ```

### Tela 5 — Revisão + Envio
- Revise TUDO
- Se estiver ok, clique **"Enviar para revisão"** (não é publicação, só salva pra quando você for publicar o app)

---

## 🎯 Ao terminar as 5

Vá em `App content → Overview`. Deve mostrar **"0 declarações precisam de atenção"** e todas devem estar em **"Com medidas tomadas"**.

Isso desbloqueia:
- Upload do primeiro APK/AAB no **"Testes internos"**
- Envio pra **"Testes fechados"** (com sua lista de testers)
- Depois: **"Produção"**

---

## 📌 Se der pau em alguma pergunta

**Nunca invente resposta em Data Safety** — Google banimento é imediato se descobrir divergência. Se dúvida:
1. Marque conservador (menos coleta, menos compartilhamento)
2. Me avise qual pergunta específica pegou dúvida — retorno com resposta baseada no código real

**Se der classificação IARC maior que Livre**: revise "substâncias controladas" — GLP-1 sob prescrição médica **não** é droga.

---

**Depois de terminar as 5, me avisa "ok" e eu volto pra**:
- Fazer os últimos ajustes no APK (`versionCode`, `targetSdk 35` já feitos — só falta fazer upload)
- Criar a Ficha da loja (COPY.md tem os textos)
- Configurar OAuth Google (mata o 503 no login social)
- Preparar SKUs Play Billing quando você tiver o Merchant Center ativo
