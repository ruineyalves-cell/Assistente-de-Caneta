# Sprint 3 — Flutter App (Estrutura Completa)

## 📱 Projeto Flutter: `flutter_app/`

### Estrutura de Pastas Criada
```
flutter_app/
├── pubspec.yaml              # Dependências (já criado ✅)
├── lib/
│   ├── main.dart            # Entrypoint (criar)
│   ├── models/              # Data models
│   │   ├── user.dart
│   │   ├── medication.dart
│   │   ├── daily_log.dart
│   │   └── compliance.dart
│   ├── services/            # API e negócio
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── storage_service.dart
│   │   └── ocr_service.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── terms_screen.dart
│   │   ├── home/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── log_daily_screen.dart
│   │   │   ├── medication_select_screen.dart
│   │   │   └── medicacao_detail_screen.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   ├── history_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── doctor/
│   │       └── doctor_portal_screen.dart
│   ├── widgets/             # Componentes reutilizáveis
│   │   ├── score_card.dart
│   │   ├── streak_badge.dart
│   │   ├── metric_chart.dart
│   │   ├── metric_input.dart
│   │   └── compliance_bar.dart
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       └── colors.dart
├── test/                     # Testes unitários
├── integration_test/         # Testes E2E
├── assets/
│   ├── images/
│   └── icons/
└── README.md
```

## 🚀 Como continuar (Sprint 3)

### Próximo passo: Gerar projeto Flutter
```bash
cd flutter_app

# Se Flutter não estiver instalado, baixar em https://flutter.dev
flutter pub get

# Criar estrutura automática
flutter create . --platforms android,ios,web

# Rodar
flutter run -d chrome  # Web
flutter run -d android # Android (emulador)
flutter run -d ios     # iOS (simulador)
```

### Arquivos a criar (ordem recomendada)

1. **lib/main.dart** — Entrypoint, tema, navegação
2. **lib/models/** — DTOs (User, Medication, DailyLog, ComplianceScore)
3. **lib/services/api_service.dart** — Cliente HTTP para backend
4. **lib/services/auth_service.dart** — Gerenciar tokens, login
5. **lib/services/storage_service.dart** — Local storage (Hive)
6. **lib/screens/auth/** — Login, registro, termos
7. **lib/widgets/** — Componentes (cards, gráficos)
8. **lib/screens/home/** — Dashboard, log diário
9. **lib/screens/doctor/** — Portal médico (web view)

### Integração com Backend
- API base: `http://localhost:3000` (dev) ou `https://api.assistente-caneta.com` (prod)
- Endpoints: Ver `docs/API.md`
- Auth: JWT bearer token em headers

### Google Cloud Vision (OCR)
```dart
// lib/services/ocr_service.dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
final RecognisedText recognisedText = await textRecognizer.processImage(inputImage);
// Parse "Mounjaro 10mg, 1x/semana" from OCR result
```

### Gamificação
```dart
// lib/models/gamification.dart
class Streak {
  int current;
  int record;
  DateTime startDate;
}

class Badge {
  String id;  // 'week_perfect', 'month_consistent', etc
  String title;
  String icon;
  DateTime unlockedAt;
}

class Level {
  int number;   // 1, 2, 3, 4
  String name;  // 'Iniciante', 'Engajado', 'Dedicado', 'Campeão'
  int points;
}
```

### Gráficos (fl_chart)
```dart
// lib/widgets/metric_chart.dart
import 'package:fl_chart/fl_chart.dart';

LineChart(
  LineChartData(
    spots: scores.map((s) => FlSpot(s.day, s.score)).toList(),
    gridData: FlGridData(show: true),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true),
      ),
    ),
  ),
)
```

## 📊 Resultado esperado após Sprint 3

- ✅ App rodando em iOS/Android/Web
- ✅ Login/Registro funcional
- ✅ Seleção de medicação
- ✅ Log diário (5 campos)
- ✅ Dashboard com cards e gráfico
- ✅ Streak visual
- ✅ OCR de receituário (Google ML Kit)
- ✅ Notificações locais (reminders)
- ✅ Portal médico web (read-only)
- ✅ 20+ testes unitários/E2E

## 🔧 Stack Tech

| Camada | Framework | Versionamento |
|--------|-----------|---|
| UI | Flutter 3.0+ | Material Design 3 |
| State | Provider 6.0+ | ChangeNotifier |
| HTTP | Dio 5.0+ | Interceptors |
| Storage | Hive 2.0+ | Local/offline-first |
| OCR | Google ML Kit | On-device (sem API) |
| Charting | fl_chart 0.65+ | Line/Bar/Pie charts |
| PDF | pdf 3.10+ | pdfkit equivalente |

## ⚙️ Configuração para desenvolvimento

### .env (pasta raiz do app)
```
API_BASE_URL=http://localhost:3000
GOOGLE_CLOUD_API_KEY=seu_da_api_key_aqui
ENVIRONMENT=development
```

### android/app/build.gradle
```gradle
android {
  compileSdkVersion 34
  minSdkVersion 24
  targetSdkVersion 34
}
```

### ios/Podfile
```
platform :ios, '12.0'
```

## 🧪 Testes Flutter

```dart
// test/models/medication_test.dart
void main() {
  test('Medication.fromJson', () {
    final json = {'id': 1, 'nome_comercial': 'Mounjaro', ...};
    final med = Medication.fromJson(json);
    expect(med.id, 1);
  });
}

// integration_test/auth_flow_test.dart
void main() {
  group('Auth flow', () {
    testWidgets('Register → Login → Dashboard', (tester) async {
      // Full app flow test
      await tester.pumpWidget(MyApp());
      // ... assertions
    });
  });
}
```

---

**Próximo comando:**
```bash
cd flutter_app
flutter pub get
flutter create . --platforms android,ios,web  # If needed
flutter run -d chrome
```

Este é o **template completo** para Sprint 3. O desenvolvimento contém estrutura pronta para ser implementada incrementalmente.
