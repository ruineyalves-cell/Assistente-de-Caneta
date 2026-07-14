# PLANO ACELERADO: 100% do App sem Bloqueios Jurídicos

**Contexto:** Você autorizou construção total. Vou estruturar tudo que NÃO depende do advogado. Ferramentas Google já incluídas.

---

## 📊 Mapa de Dependências

```
┌─────────────────────────────────────────────────────────────────┐
│ BLOQUEADO (aguarda advogado)                                    │
├─────────────────────────────────────────────────────────────────┤
│  • Conteúdo educativo final (validação de fonte)                │
│  • Disclaimer jurídico final (revisão)                          │
│  • Launch público (até ter parecer)                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ LIBERADO AGORA (tudo daqui para baixo)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ✅ Backend completo (testes E2E)                               │
│ ✅ Flutter UI (iOS/Android/Web)                                │
│ ✅ Google Cloud Vision (OCR receituário)                       │
│ ✅ Portal médico (read-only)                                   │
│ ✅ Gamificação (streaks, badges)                               │
│ ✅ Gráficos e dashboards                                       │
│ ✅ Relatório PDF refinado                                      │
│ ✅ Notificações push                                           │
│ ✅ CI/CD (GitHub Actions)                                      │
│ ✅ Deploy Railway                                              │
│ ✅ Testes (Supertest, Flutter integration)                     │
│ ✅ Documentação API (Swagger)                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Roadmap em 4 Sprints (3-4 semanas)

### **Sprint 2 (Esta semana) — Backend Finalizado**
**Foco:** Testes E2E, validações, refinamentos

- ✅ Testes de integração com PostgreSQL (Supertest)
- ✅ Validações Zod em todos endpoints (tipos rigorosos)
- ✅ Rate limiting ajustado
- ✅ Swagger/OpenAPI documentado
- ✅ Mock fixtures (usuarios de teste, dados pré-preenchidos)
- ⏭️ **Resultado:** Backend 100% pronto, testado, documentado

### **Sprint 3 (Semana 2) — Flutter UI + Google Vision**
**Foco:** App funcional com autenticação

- ✅ Flutter project (iOS/Android/Web)
- ✅ Tela de login/registro
- ✅ Seleção medicação (dropdown + confirmação)
- ✅ Log diário (5 campos: peso, proteína, água, alimentos, efeitos)
- ✅ Dashboard (cards com métricas, streak, gráfico 28 dias)
- ✅ Google Cloud Vision OCR (receituário)
- ✅ Health Connect simulado (ler dados, não escrever)
- ✅ Notificações push (local, sem push remote ainda)
- ⏭️ **Resultado:** App completamente funcional em 3 plataformas

### **Sprint 4 (Semana 3) — Portal Médico + Gamificação**
**Foco:** Features avançadas

- ✅ Portal médico web (read-only)
- ✅ Autenticação profissional (CRM/CRN)
- ✅ Vínculo paciente↔profissional visual
- ✅ Visualização de dados do paciente
- ✅ PDF automático com disclaimer
- ✅ Gamificação (streaks, badges, níveis)
- ✅ Testes de integração (Flutter + Backend)
- ⏭️ **Resultado:** App 90% completo

### **Sprint 5 (Semana 4) — Deploy + Beta**
**Foco:** Pronto para beta testers

- ✅ Deploy backend em Railway
- ✅ Deploy Flutter web em Vercel/Render
- ✅ CI/CD GitHub Actions (testes + build automático)
- ✅ Configuração Google Cloud (Vision API keys)
- ✅ Firebase setup (auth, analytics — opcional)
- ✅ Documentação final (guia do usuário)
- ✅ Beta testers (30-50 usuários)
- ⏭️ **Resultado:** App 100% em produção (beta)

---

## 🔧 Detalhes Técnicos por Sprint

### **Sprint 2 Detalhado**

#### Backend - Testes E2E
```javascript
// tests/auth.e2e.test.js
describe('Auth flow', () => {
  test('Registrar → Consentimento LGPD → Login → Acessar medicações', async () => {
    // 1. Registrar
    const regResp = await request(app)
      .post('/api/auth/registrar')
      .send({ nome: 'Test', email: 'test@ex.com', ...});
    expect(regResp.status).toBe(201);
    
    // 2. Consentimento LGPD (HTTP 451 se não aceitar)
    const consentResp = await request(app)
      .post('/api/lgpd/consentimento')
      .set('Authorization', `Bearer ${regResp.body.accessToken}`)
      .send({ tipo: 'privacidade_saude', versaoDoc: '0.1', aceito: true });
    expect(consentResp.status).toBe(201);
    
    // 3. Login
    const loginResp = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@ex.com', senha: 'Senha123!' });
    expect(loginResp.status).toBe(200);
    
    // 4. POST log diário
    const logResp = await request(app)
      .post('/api/logs')
      .set('Authorization', `Bearer ${loginResp.body.accessToken}`)
      .send({ pesoKg: 98, proteinaG: 100, aguaMl: 2500, doseAplicada: true });
    expect(logResp.status).toBe(201);
    expect(logResp.body.score).toBeDefined();
  });
});
```

#### Validações Zod
- Todos os schemas validados (min/max, regex, dates)
- Erros estruturados por campo
- Testes de validação (5 testes por endpoint)

#### Swagger
```javascript
// Documentação OpenAPI auto-gerada
// GET /api/docs → interface Swagger UI
// Todos 25 endpoints documentados
```

---

### **Sprint 3 Detalhado — Flutter**

#### Estrutura
```
flutter_app/
├── lib/
│   ├── main.dart              # App root
│   ├── models/
│   │   ├── user.dart
│   │   ├── medication.dart
│   │   ├── daily_log.dart
│   │   └── compliance_score.dart
│   ├── services/
│   │   ├── api_service.dart   # HTTP client
│   │   ├── auth_service.dart  # JWT + refresh
│   │   ├── health_connect.dart # Simulado
│   │   └── google_vision.dart  # OCR
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── log_daily_screen.dart
│   │   │   └── medication_select_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   └── doctor/
│   │       └── doctor_portal_screen.dart
│   ├── widgets/
│   │   ├── score_card.dart
│   │   ├── streak_badge.dart
│   │   ├── metric_chart.dart  # Gráfico 28 dias
│   │   └── compliance_bar.dart
│   └── utils/
│       ├── constants.dart
│       ├── colors.dart
│       └── validators.dart
├── pubspec.yaml               # Dependências
├── test/                       # Testes Flutter
└── integration_test/           # Testes E2E
```

#### Dependências (pubspec.yaml)
```yaml
dependencies:
  flutter: sdk: flutter
  
  # HTTP
  http: ^1.1.0
  
  # Auth
  flutter_secure_storage: ^9.0.0
  
  # State management
  provider: ^6.0.0
  
  # UI
  fl_chart: ^0.65.0           # Gráficos
  cupertino_icons: ^1.0.0
  
  # Integração Google
  google_mlkit_text_recognition: ^0.13.0  # OCR local (alternativa Vision)
  health: ^8.0.0              # Health Connect
  
  # Utilidades
  intl: ^0.19.0               # Datas/moedas
  uuid: ^4.0.0
  
  # PDF
  pdf: ^3.10.0
  
  # Notificações
  flutter_local_notifications: ^16.0.0

dev_dependencies:
  flutter_test: sdk: flutter
  integration_test: sdk: flutter
  test: ^1.25.0
```

#### Tela de Dashboard
```dart
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    _fetchDashboard();
    _scheduleNotifications(); // Lembrete água, proteína
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assistente de Caneta')),
      body: ListView(
        children: [
          // Card 1: Medicação atual
          MedicationCard(medication: state.perfil.medicacao),
          
          // Card 2: Score de hoje
          ScoreCard(score: state.scoreHoje, componentes: state.componentes),
          
          // Card 3: Streak
          StreakBadge(streak: state.streak, meta: 30),
          
          // Card 4: Gráfico 28 dias
          LineChart(scores: state.scores28dias),
          
          // Card 5: CTA Log diário
          FloatingActionButton.extended(
            onPressed: () => Navigator.push(...LogDailyScreen()),
            label: Text('Registrar de hoje'),
          ),
        ],
      ),
    );
  }
}
```

#### Google Cloud Vision (OCR)
```dart
class GoogleVisionService {
  final apiKey = 'YOUR_GOOGLE_CLOUD_KEY'; // From .env
  
  Future<String> extractReceituario(File image) async {
    final bytes = await image.readAsBytes();
    final base64 = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'requests': [
          {
            'image': {'content': base64},
            'features': [
              {'type': 'TEXT_DETECTION'},
              {'type': 'DOCUMENT_TEXT_DETECTION'}
            ]
          }
        ]
      }),
    );
    
    // Parse resposta, extrai medicação/dose/frequência
    final medicacao = _parseMedicacao(response.body);
    return medicacao; // Ex.: "Mounjaro 10mg, 1x/semana"
  }
}
```

---

### **Sprint 4 Detalhado — Portal Médico + Gamificação**

#### Portal Médico (Web + Mobile)
```flutter
class DoctorPortalScreen extends StatefulWidget {
  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> {
  List<Patient> meusPacientes = [];
  
  @override
  void initState() {
    _fetchPacientes(); // GET /api/portal/pacientes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Portal Profissional')),
      body: ListView(
        children: meusPacientes.map((p) => PatientCard(
          nome: p.nome,
          medicacao: p.medicacao,
          score: p.scoreUltimo,
          streak: p.streak,
          onTap: () => _visualizarDashboard(p.id),
        )).toList(),
      ),
    );
  }

  void _visualizarDashboard(String patientId) {
    // GET /api/portal/pacientes/:id
    // Mostra: logs, scores, gráficos, vínculo
    
    // Botão de gerar PDF
    // GET /api/portal/pacientes/:id/relatorio.pdf → download automático
  }
}
```

#### Gamificação
```dart
class GamificationService {
  // Streaks
  int calculateStreak(List<String> logsData, String hoje) {
    // Implementado em backend (src/utils/metrics.js)
    // Replicado em Flutter para UI
  }

  // Badges
  List<Badge> calculateBadges(UserStats stats) {
    List<Badge> badges = [];
    
    if (stats.streak >= 7) badges.add(Badge('Semana Perfeita', 'icon'));
    if (stats.streak >= 30) badges.add(Badge('Mês Consistente', 'icon'));
    if (stats.avgScore >= 90) badges.add(Badge('Excelência', 'icon'));
    if (stats.logsCount >= 50) badges.add(Badge('50 Dias Registrados', 'icon'));
    
    return badges;
  }

  // Níveis (visual, gamification only)
  Level calculateLevel(int points) {
    // Pontos por: registro diário, score alto, streak, badges
    if (points < 100) return Level(1, 'Iniciante');
    if (points < 300) return Level(2, 'Engajado');
    if (points < 500) return Level(3, 'Dedicado');
    return Level(4, 'Campeão');
  }
}
```

---

### **Sprint 5 Detalhado — Deploy + CI/CD**

#### GitHub Actions CI/CD
```yaml
# .github/workflows/tests.yml
name: Tests
on: [push, pull_request]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd backend && npm install
      - run: cd backend && npm test
      - run: cd backend && npm run db:migrate
  
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd flutter_app && flutter pub get
      - run: cd flutter_app && flutter analyze
      - run: cd flutter_app && flutter test
      - run: cd flutter_app && flutter build web --release
```

#### Deploy Railway
```bash
# Automaticamente: git push origin main → Railway redeploya
# Variáveis de ambiente (Settings → Variables):
DATABASE_URL=postgresql://...
JWT_SECRET=...
DATA_ENCRYPTION_KEY=...
GOOGLE_CLOUD_API_KEY=...
```

#### Deploy Flutter Web
```bash
# Vercel
vercel --prod
```

---

## 🔌 Integração Google Cloud

### Setup (você faz uma vez)
1. **Google Cloud Console** → Nova projeto "assistente-caneta"
2. **Ativar APIs:**
   - Cloud Vision API (OCR receituário)
   - Cloud Natural Language (análise sentimento — opcional)
3. **Criar Service Account** → Download JSON
4. **Copiar chave para `.env`:**
   ```
   GOOGLE_CLOUD_API_KEY=xxxxx
   GOOGLE_CLOUD_PROJECT_ID=assistente-caneta-xxxxx
   ```

### Uso
```javascript
// backend/src/utils/ocr.js
const vision = require('@google-cloud/vision');
const client = new vision.ImageAnnotatorClient();

async function extractTextFromReceipt(imageBuffer) {
  const result = await client.textDetection({
    image: { content: imageBuffer },
  });
  
  const texts = result[0].fullTextAnnotation.text;
  // Parse: Mounjaro, 10mg, 1x/semana
  return parseMedicationFromText(texts);
}
```

---

## 📈 Métricas de Sucesso (Sprint 2-5)

| Sprint | Métrica | Target |
|--------|---------|--------|
| 2 | Cobertura de testes | 80%+ |
| 2 | Endpoints documentados (Swagger) | 25/25 |
| 3 | Screens implementadas | 8/8 |
| 3 | Testes Flutter | 20+ testes |
| 4 | Portal médico funcional | ✅ |
| 4 | Badges implementadas | 5+ |
| 5 | Uptime em staging | 99%+ |
| 5 | Build time (CI/CD) | < 5 min |

---

## ⚠️ Riscos + Mitigação

| Risco | Mitigação |
|-------|-----------|
| Flutter learning curve | Usar templates prontos, componentes Pub.dev |
| Google Cloud costs | OCR: 1-50 free/dia em dev, pagar depois em prod |
| Integração Health Connect | Simulado no MVP, real na v1.1 |
| Testing coverage | Jest + Supertest (backend), Flutter integration (app) |

---

## 🎯 Resultado final após Sprint 5

### ✅ App 100% funcional
- iOS/Android/Web rodando
- Backend em produção
- Portal médico ativo
- Gamificação completa
- OCR de receituário
- Testes 80%+ cobertura
- CI/CD automatizado
- Documentação Swagger

### ⏳ Aguardando advogado
- Parecer jurídico (conteúdo educativo)
- Validação LGPD final
- Configuração profissional (CRM/CRN real)

### 🚀 Pronto para
- Beta testers (30-50 usuários)
- Validação de mercado
- Ajustes finais pós-feedback

---

## 🏁 Cronograma

```
Hoje (14/7)
└─ Sprint 1 concluído ✅

Próxima semana (15-21/7)
└─ Sprint 2: Backend E2E + testes
   └─ Resultado: Backend 100% testado

Semana 2 (22-28/7)
└─ Sprint 3: Flutter UI completa
   └─ Resultado: App funcional em 3 plataformas

Semana 3 (29/7-4/8)
└─ Sprint 4: Portal + gamificação
   └─ Resultado: App 90% completo

Semana 4 (5-11/8)
└─ Sprint 5: Deploy + beta
   └─ Resultado: App 100% em produção

Total: 4 semanas para app 100% pronto
```

---

**Você quer começar agora? Confirme e eu inicio Sprint 2 (testes E2E) hoje mesmo.**
