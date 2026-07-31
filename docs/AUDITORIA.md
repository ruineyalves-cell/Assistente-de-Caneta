# Auditoria de Código × PRD

**Data:** 2026-07-16
**Fonte de verdade:** `docs/PRD.md` (produto **MyoSync** — DTx de recomposição corporal)
**Código auditado:** `flutter_app/lib/**` (app legado **"Assistente de Caneta"** — rastreio de conformidade GLP-1)
**Modo:** somente leitura — nenhum arquivo de código foi alterado.

> ⚠️ **Achado transversal nº 1 (o mais importante):** o PRD descreve o produto **MyoSync** com 6 telas de recomposição corporal (Disclaimer → ProfileConfig → Dashboard → CameraScanner → DietScanner → Report). O código atual é o **app anterior** ("Assistente de Caneta"), um rastreador de conformidade GLP-1 com fluxo Login → Dashboard (streak/score) → Log diário → Histórico → Perfil. **Há divergência de produto, não apenas de features.** A maior parte das funcionalidades-core do PRD simplesmente ainda não existe.
>
> ⚠️ **Achado transversal nº 2:** as dependências adicionadas ao `pubspec.yaml` (riverpod, shared_preferences, health, camera, image_picker, mlkit, pdf, printing) **estão instaladas mas não são usadas em nenhum arquivo** de `lib/`. Foram provisionadas para os recursos que ainda serão construídos.

---

## 1. INVENTÁRIO — o que existe hoje

### `lib/main.dart` (~1150 linhas — tudo num arquivo só)
Concentra o app inteiro. Contém múltiplas telas como classes no mesmo arquivo:
- **`MyApp`** — `MaterialApp`, tema M3 com seed `Colors.deepPurple`, locale pt-BR, roteia entre `DashboardPage` e `LoginPage` conforme autenticação.
- **`LoginPage`** — email/senha (com toggle mostrar/ocultar), erro inline, link p/ cadastro, caixa de disclaimer médico.
- **`RegisterPage`** — nome, email, senha, data de nascimento (date picker BR), aceite de termos obrigatório via bottom sheet, validações.
- **`DashboardPage`** — `Scaffold` com `BottomNavigationBar` de 3 abas (Home, Histórico, Perfil).
- **`HomePage`** — card de medicação **hardcoded ("Mounjaro 10mg")**, `StreakBadge`, `ScoreCard`, `MetricChart` (28 dias), botão "Registrar de hoje", dica de hidratação fixa.
- **`LogDailyPage`** — formulário: peso, proteína, água, alimentos, "dose aplicada". Salva via `LogsProvider`.
- **`HistoryPage`** — lista de logs com badge Completo/Incompleto e data formatada.
- **`ProfilePage`** — **somente leitura**: avatar, nome, email, ListTiles inertes (`onTap: () {}`), aviso de versão.
- **`_TermosSheet`** — termos LGPD com trava de rolagem até o fim antes de habilitar "Aceito".

### `lib/models/`
- **`user.dart`** — `User` (id, nome, email, role, dataNascimento, idadeAnos). **Sem gênero, sexo biológico ou eixo farmacológico.**
- **`medication.dart`** — `Medication` (nome comercial, princípio ativo, status Anvisa…).
- **`daily_log.dart`** — `DailyLog` (peso, proteína, água, alimentos, doseAplicada, efeitos). `isComplete`.
- **`compliance_score.dart`** — `ComplianceScore` (score 0-100, componentes proteína/hidratação/registro, alertas). **Sem gordura/massa magra.**
- **`index.dart`** — barrel de exports.

### `lib/services/`
- **`api_service.dart`** — cliente Dio p/ backend Render. Endpoints: auth (registrar/login/refresh/logout), medicações, **perfil (`salvarPerfil`/`obterPerfil`)**, logs (registrar/listar/dashboard), LGPD (consentimento/exportar). Interceptor de refresh 401.
- **`auth_service.dart`** — `ChangeNotifier`; tokens em `flutter_secure_storage`; registra consentimentos LGPD no login.
- **`logs_provider.dart`** — `ChangeNotifier`; carrega dashboard/logs, adiciona log, calcula streak/scoreToday.

### `lib/widgets/`
- **`metric_chart.dart`** — **usa `fl_chart` (`LineChart`)**, altura 200, min/máx/média. ✅ não é gráfico à mão.
- **`score_card.dart`** — card de score 0-100 com cor por faixa e `LinearProgressIndicator`.
- **`streak_badge.dart`** — badge circular de streak (🔥).

### `lib/utils/`
- **`constants.dart`** — URL do backend, strings, disclaimer médico, metas (proteína 1.2g/kg, água 35ml/kg).
- **`validators.dart`** — validações de email, senha, nome, data (≥18), peso, altura, proteína, água.

---

## 2. CONFORMIDADE COM O PRD

| # | Funcionalidade core (PRD) | Status | Evidência |
|---|---|---|---|
| 1 | **Disclaimer (LGPD/HIPAA)** | 🟡 **PARCIAL** | LGPD bem coberto (`_TermosSheet`, `disclaimerMedico`, consentimentos no `auth_service`). Porém **não há tela dedicada de gate** ("Compreendo e Aceito" como 1ª tela) e **HIPAA não é mencionado** em lugar nenhum. |
| 2 | **Perfil (gênero + sexo biológico + eixo farmacológico)** | 🔴 **FALTANDO** | `ProfilePage` é só leitura (nome/email). Nenhum campo de identidade de gênero, sexo biológico ou eixo farmacológico (GLP-1/Duplo/Triplo/Miostatina/Natural). `salvarPerfil` existe na API mas **não é chamado por nenhuma UI** e não contém esses campos. |
| 3 | **Dashboard de recomposição** | 🟡 **PARCIAL** | Existe um dashboard, mas é o de **conformidade** (streak, score, chart de %). **Falta** a semântica de recomposição do PRD: peso com ±, indicadores de gordura ↓ e massa magra ↑, foco "Blindagem Muscular". Medicação está **hardcoded**. |
| 4 | **Macros de blindagem (proteína)** | 🟡 **PARCIAL** | Proteína é registrada (`LogDailyPage`), entra no score e tem meta (1.2g/kg). **Falta** o card de "Macros de Blindagem" no dashboard (proteína estrutural + carboidratos) descrito no PRD. |
| 5 | **Scanner de refeição (IA de visão)** | 🔴 **FALTANDO** | Sem `CameraScannerScreen`. `camera`/`image_picker` instalados mas não usados. |
| 6 | **OCR de prescrição** | 🔴 **FALTANDO** | Sem `DietScannerScreen`. `google_mlkit_text_recognition` instalado mas não usado. |
| 7 | **Hub de smartwatch (FC + gasto ativo + hidratação)** | 🔴 **FALTANDO** | Sem `ReportScreen`/hub. `health` (Health Connect) instalado mas não usado. Hidratação é só registro manual; sem sincronia/lembretes no relógio. |
| 8 | **Ajuste de esforço (corrida/ciclismo)** | 🔴 **FALTANDO** | Nenhum motor de ajuste de esforço, nem UI, nem modelo. |
| 9 | **Relatório PDF para médico** | 🔴 **FALTANDO** | Sem geração de PDF. `pdf`/`printing` instalados mas não usados. Existe apenas `exportarDados` (JSON via LGPD), que não é o relatório clínico do PRD. |

**Resumo:** 0 OK · 3 PARCIAL · 6 FALTANDO.

---

## 3. IDENTIDADE VISUAL

| Item do PRD | Esperado | No código | Status |
|---|---|---|---|
| Cor primária / seed | Azul Clínico `#2B6CB0` | `seedColor: Colors.deepPurple` (`main.dart:50,58`) | 🔴 fora do padrão |
| Fundo / superfície | `#F4F7FA` | `scaffoldBackgroundColor` **não definido** (usa padrão M3) | 🔴 faltando |
| Vermelho de alerta | `#E53E3E` | `Colors.red` genérico (login, erros, badges) | 🟡 aproximado, não é o hex |
| Verde de confirmação | `#48BB78` | `Colors.green` / `Colors.lightGreen` genéricos | 🟡 aproximado, não é o hex |

**Cores fora do padrão encontradas:**
- `Colors.deepPurple` como identidade primária — **conflita diretamente** com o Azul Clínico. Ocorrências: `main.dart:50,58,654`, `metric_chart.dart:109,117,125`, `streak_badge.dart:16,32,44`.
- Paleta ad-hoc espalhada: `Colors.amber` (dicas/disclaimer), `Colors.orange`, `Colors.red`, `Colors.green`, `Colors.blue` — sem um `ThemeData`/tokens centralizados.
- Não há constantes de cor no `constants.dart` (as cores do PRD não estão codificadas em lugar nenhum).

---

## 4. DÉBITOS TÉCNICOS

1. **`.withOpacity()` (deprecado)** — **12 ocorrências em 4 arquivos** (`main.dart` ×7, `streak_badge.dart` ×2, `score_card.dart` ×2, `metric_chart.dart` ×1). Deprecado nas versões recentes do Flutter; substituir por `.withValues(alpha: …)`.

2. **Gráfico desenhado à mão** — ✅ **não é um problema atual.** `metric_chart.dart` já usa `fl_chart` (`LineChart`, altura 200). O overflow de 4px e as barras à mão descritos no PRD §4 **parecem já resolvidos** neste código. Falta apenas a **média móvel** citada no PRD §5 (hoje plota valores brutos).

3. **Estado só em `setState`/`provider` sem persistência local** — todo o estado usa `setState` + `ChangeNotifier` (`provider`). **Nenhum uso de `shared_preferences`**: perfil e peso **não persistem localmente** entre sessões (dependem 100% do backend). O PRD/dependências pedem persistência local.

4. **Dependências novas não conectadas** — `flutter_riverpod`, `shared_preferences`, `health`, `camera`, `image_picker`, `google_mlkit_text_recognition`, `pdf`, `printing` estão no `pubspec.yaml` porém **sem uso algum** em `lib/` (0 imports). Coexistência de `provider` (em uso) e `riverpod` (instalado, não usado) = decisão de arquitetura pendente.

5. **Outros débitos observados (bônus):**
   - Todo o app em **um único `main.dart` de ~1150 linhas**; sem pasta `screens/` (as telas do PRD nem existem como arquivos).
   - **Medicação hardcoded** ("Mounjaro 10mg") na `HomePage`, ignorando o backend de medicações.
   - `ProfilePage` com ações mortas (`onTap: () {}`).
   - `main.dart:26` e afins usam `Key? key` + `super(key: key)` (estilo antigo; lints atuais preferem `super.key`).
   - **HIPAA** citado no escopo da auditoria não aparece em nenhum texto legal (só LGPD).

---

## 5. RECOMENDAÇÃO (para cada PARCIAL / FALTANDO)

| Item | Recomendação | Justificativa (1 linha) |
|---|---|---|
| **Disclaimer (LGPD/HIPAA)** | **APROVEITAR** | Texto LGPD, trava de rolagem e registro de consentimento já são sólidos; só extrair para uma `DisclaimerScreen` de gate e acrescentar HIPAA. |
| **Perfil (gênero/sexo/eixo)** | **REFAZER** | `ProfilePage` é só leitura e não tem os campos; criar `ProfileConfigScreen` nova (reaproveitando `salvarPerfil` da API, que precisa ganhar os novos campos). |
| **Dashboard de recomposição** | **APROVEITAR** | A base (Consumer, cards, `fl_chart`, layout) é reutilizável; evoluir o conteúdo de "conformidade" para "recomposição" (gordura ↓/massa magra ↑, blindagem). |
| **Macros de blindagem (proteína)** | **APROVEITAR** | Registro de proteína, meta e score já existem; só faltar montar o card de macros no dashboard. |
| **Scanner de refeição (IA visão)** | **REFAZER** | Não existe nada; construir `CameraScannerScreen` do zero sobre `camera`/`image_picker` (já instalados). |
| **OCR de prescrição** | **REFAZER** | Não existe nada; construir `DietScannerScreen` do zero sobre `google_mlkit_text_recognition`. |
| **Hub de smartwatch (FC/gasto/hidratação)** | **REFAZER** | Integração Health Connect inexistente; construir sobre `health` v13 (atenção à API nova). |
| **Ajuste de esforço (corrida/ciclismo)** | **REFAZER** | Sem modelo, motor ou UI; feature nova por completo. |
| **Relatório PDF para médico** | **REFAZER** | Sem geração de PDF; construir com `pdf`/`printing`, podendo reaproveitar `exportarDados` como fonte de dados. |
| **Identidade visual (#2B6CB0 / #F4F7FA)** | **APROVEITAR** | Correção barata e centralizada: trocar seed/scaffold no `ThemeData` e criar tokens de cor; estrutura de widgets não muda. |
| **`.withOpacity` deprecado** | **APROVEITAR** | Substituição mecânica por `.withValues(alpha:)` nas 12 ocorrências. |
| **Persistência local (`shared_preferences`)** | **REFAZER (camada)** | Introduzir camada de persistência local para perfil/peso; hoje inexistente. |

---

### Conclusão

O código atual é um **produto diferente** (conformidade GLP-1) do que o PRD especifica (**MyoSync**, recomposição corporal). A **fundação técnica é aproveitável** — autenticação, camada de API/Dio, LGPD, `fl_chart` e estrutura de estado são reutilizáveis — mas **6 das 9 funcionalidades-core do PRD ainda não existem** e a identidade visual está fora do padrão. O caminho recomendado é **aproveitar a base e a identidade (ajuste barato)** e **construir as telas de recomposição, visão computacional, wearables e PDF** como trabalho novo, decidindo antes se o estado migra de `provider` para `riverpod`.
