import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Erro de biometria que DEVE virar mensagem pro usuário (não um "pisca"
/// silencioso). Cancelamento pelo usuário NÃO gera esta exceção — some
/// só quando há uma condição real (hardware ausente, digital bloqueada,
/// activity errada). [mensagem] já vem pronta pra exibir em SnackBar.
class BiometriaIndisponivelException implements Exception {
  final String mensagem;
  BiometriaIndisponivelException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Login rápido via biometria (digital/face).
///
/// **Segurança sem gambiarra:**
///   1. Credenciais (email + senha) ficam em [FlutterSecureStorage],
///      que no Android usa EncryptedSharedPreferences + Keystore
///      hardware-backed (Snapdragon Security Enclave no S25). Ninguém
///      lê o arquivo bruto sem a chave do enclave.
///   2. **Gate biométrico obrigatório** antes de ler: mesmo com root,
///      o app precisa passar por local_auth.authenticate() — que só
///      resolve com digital/face válidos.
///   3. Opt-in explícito: user precisa autorizar após um login
///      bem-sucedido. Nunca ativado por padrão.
///   4. Logout, "esqueci senha", ou desativação no Perfil apagam tudo.
///
/// **Fluxo:**
///   - Após login OK → app pergunta "Ativar login rápido?"
///   - Se sim → [salvarCredenciais] (grava no cofre)
///   - Próxima abertura na tela de login → botão "Continuar com
///     biometria" se [temCredenciaisSalvas] retorna true
///   - Tap → [obterCredenciaisComBiometria] pede a digital → devolve
///     email/senha → LoginScreen chama AuthService.login normal
class BiometricLoginService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  // Chaves separadas do resto do secure_storage pra facilitar
  // limpeza granular.
  static const _kEmail = 'biometric_login_email_v1';
  static const _kSenha = 'biometric_login_senha_v1';

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  BiometricLoginService({
    FlutterSecureStorage? storage,
    LocalAuthentication? auth,
  })  : _storage = storage ??
            const FlutterSecureStorage(aOptions: _androidOptions),
        _auth = auth ?? LocalAuthentication();

  bool get suportado => !kIsWeb;

  /// True se o device tem hardware biométrico configurado e ativo.
  /// Se retornar false, escondemos o botão "Continuar com biometria"
  /// (não faz sentido oferecer o que não vai funcionar).
  Future<bool> biometriaDisponivel() async {
    if (!suportado) return false;
    try {
      final osSuporta = await _auth.isDeviceSupported();
      final podeChecar = await _auth.canCheckBiometrics;
      if (!osSuporta || !podeChecar) return false;
      final tipos = await _auth.getAvailableBiometrics();
      // strong + weak: aceita fingerprint, face, iris, whatever o
      // Samsung Pass entregar. Se lista vazia, sem biometria cadastrada.
      return tipos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True se o user já ativou login rápido em algum momento e as
  /// credenciais ainda estão no cofre. Não valida biometria aqui.
  Future<bool> temCredenciaisSalvas() async {
    if (!suportado) return false;
    try {
      final e = await _storage.read(key: _kEmail);
      final s = await _storage.read(key: _kSenha);
      return e != null && s != null && e.isNotEmpty && s.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Grava credenciais no cofre. Chame só APÓS o user aceitar o dialog
  /// de opt-in de login rápido.
  Future<bool> salvarCredenciais({
    required String email,
    required String senha,
  }) async {
    if (!suportado) return false;
    try {
      await _storage.write(key: _kEmail, value: email);
      await _storage.write(key: _kSenha, value: senha);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pede biometria e, se autenticar, devolve as credenciais salvas.
  /// Retorna null se: sem credenciais, biometria cancelada/falhou, ou
  /// storage corrompido. LoginScreen usa isto pra alimentar o
  /// AuthService.login sem o user redigitar nada.
  Future<({String email, String senha})?> obterCredenciaisComBiometria({
    String razao = 'Entrar no Recorpo',
  }) async {
    if (!suportado) return null;
    bool ok;
    try {
      ok = await _auth.authenticate(
        localizedReason: razao,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      // Traduz os códigos do local_auth em mensagens acionáveis. Sem isto,
      // qualquer falha real (activity errada, digital bloqueada, hardware
      // sem cadastro) resolvia como null e a tela só "piscava".
      throw BiometriaIndisponivelException(_mensagemDoErro(e));
    }
    // Usuário cancelou / falhou o toque: sem exceção, sem mensagem — ele
    // simplesmente digita a senha.
    if (!ok) return null;
    final email = await _storage.read(key: _kEmail);
    final senha = await _storage.read(key: _kSenha);
    if (email == null || senha == null) return null;
    return (email: email, senha: senha);
  }

  String _mensagemDoErro(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return 'Biometria indisponível neste aparelho. Entre com email e senha.';
      case auth_error.notEnrolled:
        return 'Nenhuma digital/face cadastrada no aparelho. Cadastre nas '
            'configurações do Android ou entre com email e senha.';
      case auth_error.lockedOut:
        return 'Muitas tentativas. Aguarde alguns segundos e tente de novo, '
            'ou entre com email e senha.';
      case auth_error.permanentlyLockedOut:
        return 'Biometria bloqueada. Desbloqueie o aparelho com o PIN/padrão '
            'e depois entre com email e senha.';
      case auth_error.passcodeNotSet:
        return 'Configure um bloqueio de tela no Android para usar a '
            'biometria. Por ora, entre com email e senha.';
      default:
        // Inclui "no_fragment_activity" — não deveria mais ocorrer após o
        // fix da MainActivity, mas se voltar, aparece explícito.
        return 'Não foi possível usar a biometria (${e.code}). Entre com '
            'email e senha.';
    }
  }

  /// Apaga as credenciais do cofre. Deve ser chamado em:
  ///   - logout explícito do user
  ///   - "esqueci minha senha" (senha antiga não vale mais)
  ///   - desativação manual no Perfil
  ///   - detecção de senha mudada pelo backend (401 no re-login)
  Future<void> limpar() async {
    if (!suportado) return;
    try {
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kSenha);
    } catch (_) {}
  }
}
