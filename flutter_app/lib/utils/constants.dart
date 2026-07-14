class AppConstants {
  // API
  static const String apiBaseUrl = 'http://localhost:3000'; // Dev
  // static const String apiBaseUrl = 'https://api.assistente-caneta.com'; // Prod

  // Strings
  static const String appName = 'Assistente de Caneta';
  static const String appSubtitle = 'Acompanhamento de conformidade GLP-1';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyEmail = 'email';
  static const String keyNome = 'nome';

  // Defaults
  static const double defaultMetaProteinaGkg = 1.2;
  static const double defaultMetaAguaMlkg = 35.0;

  // LGPD
  static const String disclaimerMedico = '''
⚠️ AVISO IMPORTANTE

Este aplicativo é uma ferramenta educacional de registro de conformidade.

NÃO:
- Fornece diagnóstico médico
- Substitui orientação profissional
- É um dispositivo médico

SEMPRE consulte seu médico para decisões sobre sua medicação.

Seus dados são criptografados e protegidos conforme Lei Geral de Proteção de Dados (LGPD).
  ''';

  // Metas padrão (Fonte: ABESO, MS, ADA)
  static const String metasInfo = '''
Metas de conformidade:

Proteína: 1.2g/kg (ABESO)
Hidratação: 35ml/kg (Diretrizes Saúde Pública)
Registro: Consistência diária

Fonte: Bulas oficiais Anvisa + Diretrizes públicas de saúde
  ''';
}
