import 'package:flutter/material.dart';

/// Tokens de cor da identidade visual MyoSync (fonte: docs/PRD.md §3).
class AppColors {
  /// Azul Clínico — cor primária / seed do tema.
  static const Color azulClinico = Color(0xFF2B6CB0);

  /// Fundo frio claro — superfícies e scaffold.
  static const Color fundoFrio = Color(0xFFF4F7FA);

  /// Vermelho de alerta clínico.
  static const Color vermelhoAlerta = Color(0xFFE53E3E);

  /// Verde de confirmação.
  static const Color verdeConfirma = Color(0xFF48BB78);
}

class AppConstants {
  // API
  // static const String apiBaseUrl = 'http://localhost:3000'; // Dev
  static const String apiBaseUrl = 'https://assistente-caneta-backend-tkl7.onrender.com'; // Prod

  // Strings
  static const String brandName = 'Recorpo'; // marca principal
  static const String appName =
      'Assistente de Caneta'; // descritor complementar
  static const String appSubtitle = 'Acompanhamento de conformidade GLP-1';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyEmail = 'email';
  static const String keyNome = 'nome';
  static const String keyDisclaimerAceito = 'disclaimer_aceito_v1';
  // Lote 29 — Onboarding em 3 telas (boas-vindas, medicação, meta de peso).
  // Só é exibido uma vez após o primeiro login; a flag é persistida
  // por usuário quando ele conclui as três etapas ou opta por pular.
  static const String keyOnboardingCompleto = 'onboarding_completo_v1';

  // Defaults
  static const double defaultMetaProteinaGkg = 1.2;
  static const double defaultMetaAguaMlkg = 35.0;

  // Texto completo dos Termos de Uso e Política de Privacidade — fonte única
  // consumida pelo DisclaimerScreen (gate de 1ª execução) e pelo _TermosSheet
  // (RegisterPage). Ajustes legais devem entrar aqui.
  static const String termosLegaisTexto = '''
TERMOS DE USO E POLÍTICA DE PRIVACIDADE
Recorpo (Assistente de Caneta) — versão 0.1.0 (beta)

1. NATUREZA DO APLICATIVO
Este aplicativo é uma ferramenta educacional de registro e acompanhamento de conformidade para pessoas em tratamento com medicamentos da classe GLP-1/GIP. Ele NÃO fornece diagnóstico, NÃO substitui a orientação de profissionais de saúde e NÃO é um dispositivo médico.

2. USO PERMITIDO
2.1. O uso é permitido apenas para maiores de 18 anos.
2.2. Você é responsável pela veracidade dos dados que registra.
2.3. As informações educativas exibidas são reproduções de fontes oficiais (bulas Anvisa, ABESO, Ministério da Saúde, ADA), sempre citadas.

3. DADOS E PRIVACIDADE (LGPD — Lei 13.709/2018)
3.1. Seus dados de saúde são dados sensíveis e tratados com base no seu consentimento (art. 11).
3.2. Os dados são criptografados em trânsito (HTTPS) e sensíveis são cifrados no servidor.
3.3. Você pode, a qualquer momento: acessar, corrigir, exportar e solicitar a exclusão dos seus dados.
3.4. A exclusão remove sua conta e agenda a eliminação definitiva dos dados em até 30 dias.
3.5. Não vendemos nem compartilhamos seus dados com terceiros para fins de marketing.

4. PADRÃO INTERNACIONAL DE SIGILO (HIPAA)
4.1. Ainda que a norma aplicável ao Brasil seja a LGPD, quando os dados forem processados por infraestrutura sediada nos Estados Unidos ou por prestadores sujeitos à Health Insurance Portability and Accountability Act (HIPAA), o mesmo padrão de sigilo é observado: seus dados de saúde são tratados como Protected Health Information (PHI), com acesso restrito, registro de auditoria e ciframento em repouso.
4.2. Não realizamos venda de PHI e não usamos PHI para publicidade dirigida.

5. LIMITAÇÃO DE RESPONSABILIDADE
5.1. As decisões sobre sua medicação, dose e tratamento devem ser sempre tomadas com seu médico.
5.2. O aplicativo não se responsabiliza por decisões tomadas exclusivamente com base nos registros ou alertas exibidos.

6. SEGURANÇA
6.1. Mantenha sua senha em sigilo.
6.2. Em caso de suspeita de acesso indevido, altere sua senha.

7. ALTERAÇÕES
Estes termos podem ser atualizados. Mudanças relevantes serão comunicadas no aplicativo.

8. CONTATO
Dúvidas sobre privacidade e seus direitos podem ser encaminhadas ao controlador dos dados pelo canal de suporte informado no aplicativo.

Ao tocar em "Compreendo e Aceito", você declara ter lido e concordado com os Termos de Uso e a Política de Privacidade acima, incluindo as menções à LGPD e ao padrão HIPAA, e consente com o tratamento dos seus dados de saúde para a finalidade de acompanhamento de conformidade.
''';

  // LGPD (box curto — usado no login e no dashboard)
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
