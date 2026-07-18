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

  GoogleSignIn _lazy() {
    return _google ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
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
    if (msg.contains('DEVELOPER_ERROR') || msg.contains('10:')) {
      return 'Login social ainda não configurado. Peça ao suporte pra concluir a '
          'configuração no Firebase (SHA-1 + OAuth Client ID).';
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
