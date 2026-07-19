import 'package:dio/dio.dart';

class ApiService {
  // Backend de produção (Render). O plano gratuito "hiberna": a primeira
  // requisição após inatividade pode levar até ~60s para responder.
  static const String baseUrl =
      'https://assistente-caneta-backend-tkl7.onrender.com';

  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 70),
        receiveTimeout: const Duration(seconds: 70),
        sendTimeout: const Duration(seconds: 70),
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

          // 502/503/504 → o Render free tier hibernou e está acordando.
          // Damos até 2 tentativas com backoff antes de repassar o erro.
          final status = error.response?.statusCode;
          if ((status == 502 || status == 503 || status == 504)) {
            final opts = error.requestOptions;
            final tentativa = (opts.extra['retry_5xx'] as int?) ?? 0;
            if (tentativa < 2) {
              await Future.delayed(Duration(seconds: 3 + tentativa * 4));
              opts.extra['retry_5xx'] = tentativa + 1;
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.reject(retryError);
              }
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
          'dataNascimento': dataNascimento,
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
      setTokens(data['accessToken'] as String, data['refreshToken'] as String);
      return data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Lote 20 — Login social via provedor OAuth (hoje: Google).
  /// Envia o `idToken` pro backend, que valida a assinatura Google e
  /// devolve os tokens JWT do próprio Recorpo. Também usado quando
  /// usuário nunca esteve no app (cria conta on-the-fly).
  Future<Map<String, dynamic>> loginSocial({
    required String provedor, // 'google', futuramente 'apple'
    required String idToken,
    String? emailFallback,
    String? nomeFallback,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/oauth-social',
        data: {
          'provedor': provedor,
          'idToken': idToken,
          if (emailFallback != null) 'email': emailFallback,
          if (nomeFallback != null) 'nome': nomeFallback,
        },
      );
      final data = response.data as Map<String, dynamic>;
      setTokens(data['accessToken'] as String, data['refreshToken'] as String);
      return data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> refreshTokens() async {
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      // O refresh retorna apenas um novo accessToken; mantém o refreshToken atual.
      setTokens(data['accessToken'] as String, _refreshToken!);
      return data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout', data: {'refreshToken': _refreshToken});
      clearTokens();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== MEDICAÇÕES ==========

  Future<List<Map<String, dynamic>>> listarMedicacoes() async {
    try {
      final response = await _dio.get('/api/medicacoes');
      // Backend responde { medicacoes: [...] }.
      final data = response.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(
          (data['medicacoes'] as List?) ?? const []);
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

  /// Salva/atualiza o perfil do paciente. Todos os campos são opcionais,
  /// exceto [declarouPrescricao] (o backend rejeita com 403 se `false`
  /// junto de dados de medicação). Envia apenas as chaves não-nulas para
  /// que o backend preserve valores anteriores via COALESCE.
  Future<Map<String, dynamic>> salvarPerfil({
    required bool declarouPrescricao,
    int? medicacaoId,
    String? dosagem,
    double? pesoKg,
    int? alturaCm,
    double? metaProteinaGkg,
    double? metaAguaMlkg,
    // Lote 31 — perfil estendido antes só em SharedPreferences.
    String? eixoFarmacologico,
    String? identidadeGenero,
    String? sexoBiologico,
    String? ultimaDoseIso,
    double? metaPesoKg,
  }) async {
    try {
      final data = <String, dynamic>{'declarouPrescricao': declarouPrescricao};
      if (medicacaoId != null) data['medicationId'] = medicacaoId;
      if (dosagem != null) data['doseAtual'] = dosagem;
      if (pesoKg != null) data['pesoInicialKg'] = pesoKg;
      if (alturaCm != null) data['alturaCm'] = alturaCm;
      if (metaProteinaGkg != null) data['metaProteinaGkg'] = metaProteinaGkg;
      if (metaAguaMlkg != null) data['metaAguaMlKg'] = metaAguaMlkg;
      if (eixoFarmacologico != null) {
        data['eixoFarmacologico'] = eixoFarmacologico;
      }
      if (identidadeGenero != null) data['identidadeGenero'] = identidadeGenero;
      if (sexoBiologico != null) data['sexoBiologico'] = sexoBiologico;
      if (ultimaDoseIso != null) data['ultimaDoseIso'] = ultimaDoseIso;
      if (metaPesoKg != null) data['metaPesoKg'] = metaPesoKg;

      final response = await _dio.put('/api/pacientes/perfil', data: data);
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

  /// Lote 32.2 — Pré-consulta determinística. Sem IA. Retorna:
  ///  - `fatos`: peso/dose/sintomas agregados dos últimos 30 dias
  ///  - `perguntas`: até 5 perguntas curadas para o médico
  ///  - `disclaimer`: texto legal a exibir em topo e rodapé
  Future<Map<String, dynamic>> obterPreConsulta() async {
    try {
      final response = await _dio.get('/api/pacientes/pre-consulta');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Lote 32.4 — Alertas clínicos objetivos (sintoma persistente etc.).
  /// Sempre retorna a lista mesmo quando vazia — o cliente decide se
  /// mostra banner e/ou notificação.
  Future<Map<String, dynamic>> obterAlertas() async {
    try {
      final response = await _dio.get('/api/pacientes/alertas');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== LGPD (Lote 32.6) ==========

  /// Portabilidade dos dados — LGPD art. 18, V. Retorna o pacote
  /// completo (usuário + perfil + consentimentos + logs + scores).
  Future<Map<String, dynamic>> exportarDadosLgpd() async {
    try {
      final response = await _dio.get('/api/lgpd/exportar');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Auditoria de acessos aos meus dados — LGPD art. 18, VII.
  /// Retorna quem/quando/o quê nos últimos 500 registros.
  Future<List<Map<String, dynamic>>> listarAcessosLgpd() async {
    try {
      final response = await _dio.get('/api/lgpd/acessos');
      final data = response.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(
          (data['acessos'] as List?) ?? const []);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Direito de eliminação — LGPD art. 18, VI. Marca a conta para
  /// exclusão imediata; dados sensíveis são apagados definitivamente
  /// em até 30 dias (§7 da Política).
  Future<Map<String, dynamic>> excluirContaLgpd() async {
    try {
      final response = await _dio.delete(
        '/api/lgpd/conta',
        data: {'confirmo': true},
      );
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
          'pesoKg': pesoKg,
          'proteinaG': proteinaG,
          'aguaMl': aguaMl,
          'alimentos': alimentos,
          'doseAplicada': doseAplicada,
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
      if (de != null) params['desde'] = de.toIso8601String().split('T')[0];
      if (ate != null) params['ate'] = ate.toIso8601String().split('T')[0];

      final response = await _dio.get(
        '/api/logs',
        queryParameters: params,
      );
      // Backend responde { logs: [...] }.
      final data = response.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(
          (data['logs'] as List?) ?? const []);
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

  // ========== IA ==========

  /// Lote 21 — Envia base64 da foto para o backend analisar. Se o
  /// backend não tiver chave IA configurada, retorna
  /// { iaConfigurada: false } — a UI segue com os labels locais.
  Future<Map<String, dynamic>> analisarRefeicaoIA({
    required String imagemBase64,
  }) async {
    try {
      final response = await _dio.post(
        '/api/ia/refeicao',
        data: {'imagemBase64': imagemBase64},
        // Análise pode demorar mais que os 70s padrão do Render frio
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ========== LGPD ==========

  Future<void> registrarConsentimento(
    String tipo, {
    String versaoDoc = '0.1.0',
    bool aceito = true,
  }) async {
    try {
      await _dio.post(
        '/api/lgpd/consentimento',
        data: {'tipo': tipo, 'versaoDoc': versaoDoc, 'aceito': aceito},
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
    // Erros de infraestrutura do Render free tier — o serviço hiberna
    // após 15min e a primeira requisição pode voltar com 502/503/504
    // até o app subir. Damos mensagem amigável em vez do stack trace.
    final status = e.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) {
      return 'O servidor está acordando. Tente novamente em ~1 minuto.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'A resposta demorou demais. Verifique sua conexão e tente novamente.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sem conexão com o servidor. Verifique sua internet.';
    }
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
