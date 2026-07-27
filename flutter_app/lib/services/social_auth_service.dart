import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper fino em cima do google_sign_in. Aceita ausência de configuração
/// (google-services.json não gerado ainda) sem quebrar o app — apenas
/// devolve `null` em [signIn] e o botão da tela mostra a mensagem
/// amigável.
///
/// Fluxo:
///   1) [signIn] abre o consent screen do Google
///   2) A conta escolhida retorna `idToken` (JWT assinado pelo Google)
///   3) A tela de login manda esse token para
///      `POST /api/auth/oauth-google` no backend
///   4) Backend valida a assinatura, cria/associa usuário e devolve
///      accessToken/refreshToken do próprio Recorpo
class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._();
  factory SocialAuthService() => _instance;
  SocialAuthService._();

  GoogleSignIn? _google;

  bool get suportado => !kIsWeb; // Web tem fluxo próprio, deixado pra depois

  /// Web OAuth Client ID do projeto GCP `Recorpo` (conta nariz.de.perito).
  /// Passado como `serverClientId` para o plugin — assim o idToken devolvido
  /// tem `aud` = Web Client ID, que é o que o backend valida em
  /// `GOOGLE_OAUTH_CLIENT_IDS`. Sem isto, o Android usa o Client ID do
  /// próprio APK e o backend recusa o token.
  ///
  /// Substituiu o `416740367847-...` do projeto Firebase `recorpo-d39a3`
  /// (excluído em jul/2026, retornava `invalid_client`).
  ///
  /// Android OAuth Client não foi criado ainda — o Firebase antigo
  /// ainda está em soft-delete e reserva o par (package+SHA-1). Sem o
  /// Android Client, sign-in silencioso não funciona (menos crítico);
  /// o fluxo interativo (usuário clica em "Entrar com Google") funciona
  /// 100% só com Web Client via serverClientId.
  static const String _webClientId =
      '503231624179-csm7j635gbb3lf1b2h2creinpdj3s0jv.apps.googleusercontent.com';

  GoogleSignIn _lazy() {
    return _google ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _webClientId,
    );
  }

  /// Retorna o `idToken` da conta escolhida ou `null` se o usuário
  /// cancelou / configuração ausente.
  Future<SocialLoginResult?> signInComGoogle() async {
    if (!suportado) return null;
    try {
      final conta = await _lazy().signIn();
      if (conta == null) return null; // usuário cancelou
      final auth = await conta.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return SocialLoginResult(
          erro: 'Não foi possível ler seu token do Google. '
              'Confirme se o app está configurado no Firebase.',
        );
      }
      return SocialLoginResult(
        idToken: idToken,
        email: conta.email,
        nome: conta.displayName,
        photoUrl: conta.photoUrl,
      );
    } on Exception catch (e) {
      return SocialLoginResult(erro: _amigavel(e));
    }
  }

  Future<void> sair() async {
    if (!suportado || _google == null) return;
    try {
      await _google!.disconnect();
    } catch (_) {}
  }

  String _amigavel(Object e) {
    final msg = e.toString();
    // DEVELOPER_ERROR (código 10) = par package+SHA-1 do APK não bate com
    // nenhum OAuth Client Android. Enquanto o par está reservado pelo
    // Firebase antigo em soft-delete, o botão fica "desligado".
    if (msg.contains('DEVELOPER_ERROR') || msg.contains('10:')) {
      return 'Login com Google chegando em breve. Use email por enquanto.';
    }
    if (msg.contains('NETWORK') || msg.contains('network')) {
      return 'Sem conexão pra falar com o Google. Verifique sua internet.';
    }
    if (msg.contains('sign_in_canceled') || msg.contains('canceled')) {
      return 'Login cancelado.';
    }
    return 'Não foi possível entrar com o Google. Tente novamente em instantes.';
  }
}

class SocialLoginResult {
  final String? idToken;
  final String? email;
  final String? nome;
  final String? photoUrl;
  final String? erro;

  SocialLoginResult({
    this.idToken,
    this.email,
    this.nome,
    this.photoUrl,
    this.erro,
  });

  bool get ok => erro == null && idToken != null;
}
