import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'biometric_login_service.dart';
import 'social_auth_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final BiometricLoginService _biometric = BiometricLoginService();

  /// Login rápido com digital/face — API pública consumida por
  /// LoginScreen (mostrar botão) e por ProfileScreen (toggle).
  BiometricLoginService get biometric => _biometric;

  /// Acesso público ao ApiService — usado pelo main.dart para o warm-up
  /// do backend no boot (ping /health silencioso enquanto o user lê a
  /// tela de disclaimer).
  ApiService get api => _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _userId;
  String? _email;
  String? _nome;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  /// True quando a sessão foi encerrada pelo servidor (rotação de segredo,
  /// refresh reusado, revogado). Setado pelo hook do ApiService e
  /// consumido pela LoginScreen pra mostrar SnackBar amigável em vez de
  /// erro cru. LoginScreen deve chamar [consumirSessaoExpirou] após
  /// apresentar a mensagem.
  bool _sessaoExpirou = false;
  bool get sessaoExpirou => _sessaoExpirou;

  void consumirSessaoExpirou() {
    _sessaoExpirou = false;
  }

  // Getters
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  String? get email => _email;
  String? get nome => _nome;

  /// Logout silencioso — chamado quando o servidor invalida a sessão
  /// (rotação de JWT_SECRET, refresh reuse detectado, etc.). Não faz POST
  /// /auth/logout (backend já invalidou). Limpa cofre + marca flag.
  Future<void> _forcarLogoutPorExpiracao() async {
    _accessToken = null;
    _refreshToken = null;
    _apiService.clearTokens();
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    } catch (_) {}
    _sessaoExpirou = true;
    notifyListeners();
  }

  // Inicializa tokens salvos
  Future<void> initialize() async {
    // Sempre que a API rotaciona o refresh, persistimos os dois novos
    // valores no cofre. Sem isso, o próximo cold-start relogaria com
    // um refresh já revogado pelo backend (detecção de reuso mataria
    // a sessão em todos os dispositivos).
    _apiService.setOnTokensRefreshed((access, refresh) async {
      _accessToken = access;
      _refreshToken = refresh;
      try {
        await _storage.write(key: 'access_token', value: access);
        await _storage.write(key: 'refresh_token', value: refresh);
      } catch (_) {}
    });

    // Sessão morta no servidor → logout gracioso + flag pra SnackBar.
    _apiService.setOnSessionExpired(_forcarLogoutPorExpiracao);

    try {
      _accessToken = await _storage.read(key: 'access_token');
      _refreshToken = await _storage.read(key: 'refresh_token');
      _userId = await _storage.read(key: 'user_id');
      _email = await _storage.read(key: 'email');
      _nome = await _storage.read(key: 'nome');

      if (_accessToken != null && _refreshToken != null) {
        _apiService.setTokens(_accessToken!, _refreshToken!);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar tokens: $e';
    }
  }

  Future<void> register({
    required String nome,
    required String email,
    required String senha,
    required String dataNascimento,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.registrar(
        nome: nome,
        email: email,
        senha: senha,
        dataNascimento: dataNascimento,
      );

      final usuario = (response['usuario'] as Map?) ?? const {};
      _userId = usuario['id']?.toString();
      _email = email;
      _nome = nome;

      await _storage.write(key: 'user_id', value: _userId);
      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'nome', value: nome);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String senha,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Aguarda o warm-up do backend (disparado no boot em main.dart)
      // completar antes de tentar login. Se já completou, retorna
      // imediato. Se ainda está em progresso, o user vê o spinner do
      // botão Entrar (contexto claro) em vez do SnackBar "servidor
      // está acordando" (que era confuso e assustava).
      await _apiService.aguardarWarmUp();

      final response = await _apiService.login(
        email: email,
        senha: senha,
      );

      final usuario = (response['usuario'] as Map?) ?? const {};
      _accessToken = response['accessToken'] as String;
      _refreshToken = response['refreshToken'] as String;
      _userId = usuario['id']?.toString();
      _email = (usuario['email'] as String?) ?? email;
      _nome = usuario['nome'] as String?;

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      await _storage.write(key: 'user_id', value: _userId);
      await _storage.write(key: 'email', value: _email);
      if (_nome != null) {
        await _storage.write(key: 'nome', value: _nome!);
      }

      // LGPD (F1): sincroniza aceite local pré-login com o backend.
      // Se backend já tem registro (mesmo revogação), respeita — impede
      // que login "reative" consent revogado.
      await _sincronizarConsentimentoLGPD();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Lote 20 — Login via Google Sign-In. Fluxo:
  /// 1) Abre o Google consent screen (SocialAuthService)
  /// 2) Recebe o idToken assinado pelo Google
  /// 3) Envia pro backend, que valida a assinatura e cria/associa a conta
  /// 4) Persiste tokens localmente igual o login por email/senha
  ///
  /// Retorna `null` se o usuário cancelou. Joga [String] com mensagem
  /// amigável em caso de erro (mesmo padrão do login por email).
  Future<Map<String, dynamic>?> signInComGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final social = await SocialAuthService().signInComGoogle();
      if (social == null) {
        _isLoading = false;
        notifyListeners();
        return null; // cancelado
      }
      if (!social.ok) {
        _error = social.erro;
        _isLoading = false;
        notifyListeners();
        throw Exception(social.erro);
      }

      final response = await _apiService.loginSocial(
        provedor: 'google',
        idToken: social.idToken!,
        emailFallback: social.email,
        nomeFallback: social.nome,
      );

      final usuario = (response['usuario'] as Map?) ?? const {};
      _accessToken = response['accessToken'] as String;
      _refreshToken = response['refreshToken'] as String;
      _userId = usuario['id']?.toString();
      _email = (usuario['email'] as String?) ?? social.email;
      _nome = (usuario['nome'] as String?) ?? social.nome;

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      await _storage.write(key: 'user_id', value: _userId);
      await _storage.write(key: 'email', value: _email);
      if (_nome != null) {
        await _storage.write(key: 'nome', value: _nome!);
      }

      // LGPD (F1): mesmo padrão do login por email — sincroniza aceite
      // local se existir, sem sobrescrever revogação prévia no backend.
      await _sincronizarConsentimentoLGPD();

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sincroniza o aceite LGPD registrado localmente (DisclaimerScreen
  /// pré-login) com o backend — mas SÓ SE nunca houve registro pra
  /// aquele tipo. Se o backend já tem qualquer registro (aceito OU
  /// revogado), respeita a decisão prévia — impede que login "reative"
  /// consent revogado (violava art. 8º §5º LGPD).
  ///
  /// Best-effort: se a chamada falhar, tenta de novo no próximo login.
  /// Não bloqueia o fluxo.
  Future<void> _sincronizarConsentimentoLGPD() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final aceitouLocal =
          prefs.getBool(AppConstants.keyDisclaimerAceito) ?? false;
      if (!aceitouLocal) return;

      final registros = await _apiService.listarConsentimentos();
      final tiposJaRegistrados = registros.map((r) => r['tipo']).toSet();
      const tiposParaSync = [
        'privacidade_saude',
        'termos_uso',
        'disclaimer_medico',
      ];
      for (final tipo in tiposParaSync) {
        if (!tiposJaRegistrados.contains(tipo)) {
          await _apiService.registrarConsentimento(tipo);
        }
      }
    } catch (_) {
      // silencioso — próximo login tenta de novo. Não bloqueia UX.
    }
  }

  /// Login rápido usando credenciais salvas no cofre biométrico.
  /// Pede a digital/face → se OK, faz login normal com email/senha
  /// que estavam no [BiometricLoginService].
  ///
  /// Retorna:
  ///   - `true` se autenticou e logou com sucesso
  ///   - `false` se: sem credenciais salvas, biometria cancelada,
  ///     ou 401 (senha mudou no servidor — limpa cofre e força
  ///     tela de login normal)
  Future<bool> loginComBiometria() async {
    if (!await _biometric.temCredenciaisSalvas()) return false;
    final creds = await _biometric.obterCredenciaisComBiometria();
    if (creds == null) return false;
    try {
      await login(email: creds.email, senha: creds.senha);
      return true;
    } catch (e) {
      // Se a senha mudou no servidor (401), o cofre está com dado
      // stale — limpa e obriga o user a redigitar. É a única forma
      // segura de saber que a credencial expirou.
      final msg = e.toString().toLowerCase();
      if (msg.contains('inválido') ||
          msg.contains('invalido') ||
          msg.contains('senha') ||
          msg.contains('401')) {
        await _biometric.limpar();
      }
      rethrow;
    }
  }

  /// Opt-in: grava credenciais no cofre biométrico após o user
  /// aceitar o dialog "Ativar login rápido?". Idempotente — pode ser
  /// chamado múltiplas vezes com senha atualizada.
  Future<bool> ativarLoginBiometrico({
    required String email,
    required String senha,
  }) {
    return _biometric.salvarCredenciais(email: email, senha: senha);
  }

  /// Desativa login rápido (limpa cofre). User pode chamar via
  /// toggle no Perfil ou automaticamente pelo logout.
  Future<void> desativarLoginBiometrico() => _biometric.limpar();

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Guarda o refresh token pra invalidar no backend depois.
    final refreshParaInvalidar = _refreshToken;

    // Limpa estado local ANTES da chamada ao backend — se o servidor
    // estiver fora (502/cold start), o user não pode ficar preso no app.
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _nome = null;
    _apiService.clearTokens();

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'nome');
    _isLoading = false;
    notifyListeners();

    // Tenta invalidar a sessão no backend (best-effort).
    if (refreshParaInvalidar != null) {
      try {
        await _apiService.invalidarRefreshToken(refreshParaInvalidar);
      } catch (_) {}
    }
  }

  ApiService get apiService => _apiService;
}
