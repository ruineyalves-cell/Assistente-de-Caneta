import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'social_auth_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _userId;
  String? _email;
  String? _nome;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  String? get email => _email;
  String? get nome => _nome;

  // Inicializa tokens salvos
  Future<void> initialize() async {
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

      // Garante o consentimento LGPD (aceito no cadastro) para liberar os
      // dados de saúde no backend (requireConsent). Best-effort nos demais.
      try {
        await _apiService.registrarConsentimento('privacidade_saude');
        _apiService.registrarConsentimento('termos_uso');
        _apiService.registrarConsentimento('disclaimer_medico');
      } catch (_) {}

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

      // Consentimentos LGPD implícitos (o consent screen do Google já
      // pediu email/profile; o disclaimer do app cobre saúde).
      try {
        await _apiService.registrarConsentimento('privacidade_saude');
        _apiService.registrarConsentimento('termos_uso');
        _apiService.registrarConsentimento('disclaimer_medico');
      } catch (_) {}

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

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.logout();

      _accessToken = null;
      _refreshToken = null;
      _userId = null;
      _email = null;
      _nome = null;

      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'email');
      await _storage.delete(key: 'nome');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  ApiService get apiService => _apiService;
}
