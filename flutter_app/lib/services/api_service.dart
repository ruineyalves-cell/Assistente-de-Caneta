import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000'; // Dev
  // static const String baseUrl = 'https://api.assistente-caneta.com'; // Prod

  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );

    // Interceptador para adicionar token em todas as requisições
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Se 401, tenta refresh
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            try {
              final newTokens = await refreshTokens();
              // Retry original request com novo token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await _dio.request(
                opts.path,
                data: opts.data,
                queryParameters: opts.queryParameters,
                options: Options(
                  method: opts.method,
                  headers: opts.headers,
                ),
              );
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
          return handler.reject(error);
        },
      ),
    );
  }

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ========== AUTH ==========

  Future<Map<String, dynamic>> registrar({
    required String nome,
    required String email,
    required String senha,
    required String dataNascimento,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/registrar',
        data: {
          'nome': nome,
          'email': email,
          'senha': senha,
          'data_nascimento': dataNascimento,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'senha': senha,
        },
      );
      final data = response.data as Map<String, dynamic>;
      setTokens(data['access_token'] as String, data['refresh_token'] as String);
      return data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> refreshTokens() async {
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      setTokens(data['access_token'] as String, data['refresh_token'] as String);
      return data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
      clearTokens();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== MEDICAÇÕES ==========

  Future<List<Map<String, dynamic>>> listarMedicacoes() async {
    try {
      final response = await _dio.get('/api/medicacoes');
      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> detalharMedicacao(int id) async {
    try {
      final response = await _dio.get('/api/medicacoes/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== PERFIL PACIENTE ==========

  Future<Map<String, dynamic>> salvarPerfil({
    required int medicacaoId,
    required String dosagem,
    required double pesoKg,
    required int alturaCm,
    required double metaProteinaGkg,
    required double metaAguaMlkg,
    required bool declarouPrescricao,
  }) async {
    try {
      final response = await _dio.put(
        '/api/pacientes/perfil',
        data: {
          'medicacao_id': medicacaoId,
          'dosagem': dosagem,
          'peso_kg': pesoKg,
          'altura_cm': alturaCm,
          'meta_proteina_gkg': metaProteinaGkg,
          'meta_agua_mlkg': metaAguaMlkg,
          'declarou_prescricao': declarouPrescricao,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> obterPerfil() async {
    try {
      final response = await _dio.get('/api/pacientes/perfil');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== LOGS ==========

  Future<Map<String, dynamic>> registrarLog({
    required DateTime data,
    double? pesoKg,
    int? proteinaG,
    int? aguaMl,
    String? alimentos,
    bool doseAplicada = false,
    String? efeitosColaterais,
  }) async {
    try {
      final response = await _dio.post(
        '/api/logs',
        data: {
          'data': data.toIso8601String().split('T')[0],
          'peso_kg': pesoKg,
          'proteina_g': proteinaG,
          'agua_ml': aguaMl,
          'alimentos': alimentos,
          'dose_aplicada': doseAplicada,
          'efeitos': efeitosColaterais,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> listarLogs({
    DateTime? de,
    DateTime? ate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (de != null) params['de'] = de.toIso8601String().split('T')[0];
      if (ate != null) params['ate'] = ate.toIso8601String().split('T')[0];

      final response = await _dio.get(
        '/api/logs',
        queryParameters: params,
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> dashboardLogs() async {
    try {
      final response = await _dio.get('/api/logs/dashboard');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== LGPD ==========

  Future<void> registrarConsentimento(String tipo) async {
    try {
      await _dio.post(
        '/api/lgpd/consentimento',
        data: {'tipo': tipo},
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> exportarDados() async {
    try {
      final response = await _dio.get('/api/lgpd/exportar');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== UTILS ==========

  String _parseError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('erro')) {
        return data['erro'] as String;
      }
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
    }
    return e.message ?? 'Erro na requisição';
  }
}
