# Assistente de Caneta - Flutter App

App Flutter para acompanhamento de conformidade em tratamento GLP-1 no Brasil.

## 🚀 Começar

### Pré-requisitos
- Flutter 3.0+ instalado (https://flutter.dev)
- Backend rodando em `http://localhost:3000`

### Instalação

```bash
cd flutter_app
flutter pub get
```

### Rodar em Web (mais rápido para desenvolvimento)

```bash
flutter run -d chrome
```

### Rodar em Android

```bash
flutter run -d android
# ou com emulador específico:
flutter emulators --launch <emulator-id>
flutter run -d <device-id>
```

### Rodar em iOS

```bash
flutter run -d ios
```

## 📱 Estrutura do Projeto

```
lib/
├── main.dart                 # Entrypoint, temas, páginas
├── models/
│   ├── user.dart            # Modelo User
│   ├── medication.dart      # Modelo Medication
│   ├── daily_log.dart       # Modelo DailyLog
│   ├── compliance_score.dart # Modelo ComplianceScore
│   └── index.dart           # Exportações
├── services/
│   ├── api_service.dart     # Cliente HTTP (Dio)
│   ├── auth_service.dart    # Gerenciamento de autenticação (Provider)
│   └── logs_provider.dart   # Gerenciamento de logs/dashboard (Provider)
├── screens/
│   ├── home/                # Dashboard
│   ├── auth/                # Login/Register
│   └── profile/             # Perfil do usuário
├── widgets/
│   ├── score_card.dart      # Card de score
│   ├── streak_badge.dart    # Badge de streak
│   ├── metric_chart.dart    # Gráficos (fl_chart)
│   └── ...
└── utils/
    ├── constants.dart       # Constantes da app
    └── validators.dart      # Validadores de formulário
```

## 🔌 Integração com Backend

API base: `http://localhost:3000` (desenvolvimento)

### Endpoints principais

- `POST /api/auth/registrar` - Registrar novo usuário
- `POST /api/auth/login` - Login
- `GET /api/medicacoes` - Listar medicações
- `POST /api/logs` - Registrar log diário
- `GET /api/logs/dashboard` - Obter dashboard (streak, scores)

Ver documentação completa em `backend/docs/API.md`

## 🎯 Funcionalidades

- ✅ Autenticação (login/registro)
- ✅ Dashboard com streak e score
- ✅ Log diário (peso, proteína, água)
- ✅ Histórico de registros
- ✅ Perfil do usuário
- ✅ Gráfico de scores (28 dias)
- ⏳ OCR de receituário (Google ML Kit - próximo)
- ⏳ Notificações (flutter_local_notifications - próximo)
- ⏳ Portal médico (próximo)

## 🧪 Testes

```bash
flutter test
```

## 🔐 Segurança

- JWT tokens salvos em Secure Storage
- Interceptadores automaticamente adicionam `Authorization: Bearer <token>`
- Refresh token automático em 401

## 🌐 Build para Produção

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📝 Documentação

- [Backend API](../backend/docs/API.md)
- [Arquitetura](../docs/ARQUITETURA.md)
- [Segurança](../docs/SEGURANCA.md)
- [Deployment](../docs/DEPLOYMENT.md)

---

**Status:** 🟢 **DESENVOLVIMENTO ATIVO**
