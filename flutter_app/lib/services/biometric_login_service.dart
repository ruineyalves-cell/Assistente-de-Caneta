import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

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
    try {
      final ok = await _auth.authenticate(
        localizedReason: razao,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return null;
      final email = await _storage.read(key: _kEmail);
      final senha = await _storage.read(key: _kSenha);
      if (email == null || senha == null) return null;
      return (email: email, senha: senha);
    } catch (_) {
      return null;
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
