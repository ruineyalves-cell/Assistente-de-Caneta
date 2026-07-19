import 'dart:async' show unawaited;
import 'dart:convert' show jsonDecode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/dose_reminder_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_config_screen.dart';
import 'screens/app_lock_screen.dart';
import 'services/app_lock_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/feature_usage_service.dart';
import 'services/logs_provider.dart';
import 'services/premium_service.dart';
import 'services/theme_controller.dart';
import 'utils/theme.dart';
import 'widgets/quota_exceeded_sheet.dart';
import 'widgets/score_card.dart';
import 'widgets/streak_badge.dart';
import 'widgets/metric_chart.dart';
import 'widgets/recomposition_card.dart';
import 'widgets/macros_card.dart';
import 'widgets/effort_preview_card.dart';
import 'widgets/floating_nav_bar.dart';
import 'services/greeting_service.dart';
import 'services/daily_tip_service.dart';
import 'services/water_widget_service.dart';
import 'services/notification_service.dart';
import 'services/health_connect_service.dart';
import 'screens/health_hub_screen.dart';
import 'package:camera/camera.dart' show XFile;
import 'screens/camera_scanner_screen.dart';
import 'screens/diet_scanner_screen.dart';
import 'screens/meal_result_screen.dart';
import 'widgets/eixo_card.dart';
import 'widgets/symptoms_sheet.dart';
import 'widgets/water_quick_sheet.dart';
import 'widgets/weight_quick_sheet.dart';
import 'screens/effort_screen.dart';
import 'screens/pre_consulta_screen.dart';
import 'screens/report_screen.dart';
import 'models/patient_profile.dart';
import 'utils/constants.dart';
import 'utils/validators.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.initialize();

  // Lote 20/23 — Premium service (Play Billing + gate Free/Pro).
  // Inicializa após o auth para não bloquear o boot se a Play Store
  // não estiver disponível (dev/CI/web).
  final premiumService = PremiumService();
  unawaited(premiumService.inicializar());

  // Lote 24 — Controller de tema (auto/claro/escuro persistido).
  final themeController = ThemeController();
  await themeController.inicializar();

  // Lote 32.5 — App lock (PIN + biometria). Se PIN não configurado,
  // o serviço carrega vazio e o gate no MyApp não mostra AppLockScreen.
  final appLockService = await AppLockService.criar();

  final prefs = await SharedPreferences.getInstance();
  final disclaimerAceito =
      prefs.getBool(AppConstants.keyDisclaimerAceito) ?? false;
  // Lote 29 — Onboarding em 3 telas. Só é exibido uma vez após o
  // primeiro login/registro; usuário pode pular e configurar depois.
  final onboardingCompleto =
      prefs.getBool(AppConstants.keyOnboardingCompleto) ?? false;

  // Verifica se o app foi lançado a partir do App Widget do Android
  // (Lote 17). Se sim, `initialUri` fica preenchido e usado depois para
  // navegar direto à tela pedida.
  Uri? initialUri;
  if (!kIsWeb) {
    try {
      initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      // Plugin indisponível ou plataforma sem suporte — segue normal.
      initialUri = null;
    }
    // Registra o callback background do widget de Água (Lote 18) para
    // que os toques em +250/+500 sejam processados em isolate isolado.
    await const WaterWidgetService().registrarCallback();

    // Inicializa notificações locais (Lote 19). Permissão é pedida
    // pela HomePage no primeiro carregamento para não bloquear o boot.
    await NotificationService().inicializar();
  }

  runApp(MyApp(
    authService: authService,
    premiumService: premiumService,
    themeController: themeController,
    appLockService: appLockService,
    disclaimerAceitoInicial: disclaimerAceito,
    onboardingCompletoInicial: onboardingCompleto,
    initialWidgetUri: initialUri,
  ));
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  final PremiumService premiumService;
  final ThemeController themeController;
  final AppLockService appLockService;
  final bool disclaimerAceitoInicial;
  final bool onboardingCompletoInicial;

  /// URI vinda do App Widget do Android (Lote 17) — se
  /// `recorpo://scanner-refeicao`, o app roteia direto para a
  /// CameraScannerScreen assim que o gate de disclaimer estiver aceito.
  final Uri? initialWidgetUri;

  const MyApp({
    super.key,
    required this.authService,
    required this.premiumService,
    required this.themeController,
    required this.appLockService,
    required this.disclaimerAceitoInicial,
    required this.onboardingCompletoInicial,
    this.initialWidgetUri,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late bool _disclaimerAceito;
  late bool _onboardingCompleto;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _widgetIntentConsumido = false;

  @override
  void initState() {
    super.initState();
    _disclaimerAceito = widget.disclaimerAceitoInicial;
    _onboardingCompleto = widget.onboardingCompletoInicial;
    WidgetsBinding.instance.addObserver(this);
    if (_disclaimerAceito) _talvezAbrirTelaDoWidget();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Lote 32.5 — auto-lock por inatividade.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.appLockService.marcarBackground();
    } else if (state == AppLifecycleState.resumed) {
      widget.appLockService.avaliarForeground();
    }
  }

  void _onDisclaimerAceito() {
    setState(() => _disclaimerAceito = true);
    _talvezAbrirTelaDoWidget();
  }

  void _onOnboardingConcluido() {
    setState(() => _onboardingCompleto = true);
  }

  /// Se o app foi lançado pelo widget de câmera E o disclaimer já foi
  /// aceito, empurra a CameraScannerScreen no primeiro frame após o
  /// build inicial.
  void _talvezAbrirTelaDoWidget() {
    if (_widgetIntentConsumido) return;
    final uri = widget.initialWidgetUri;
    if (uri == null || !_disclaimerAceito) return;
    _widgetIntentConsumido = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _navKey.currentState;
      if (nav == null) return;
      if (uri.host == 'scanner-refeicao') {
        nav.push(MaterialPageRoute(
          builder: (_) => const CameraScannerScreen(),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: widget.authService),
        ChangeNotifierProvider<PremiumService>.value(
            value: widget.premiumService),
        ChangeNotifierProvider<ThemeController>.value(
            value: widget.themeController),
        // Lote 32.5 — App lock (PIN/biometria).
        ChangeNotifierProvider<AppLockService>.value(
            value: widget.appLockService),
        // LogsProvider é um ChangeNotifier — precisa ser exposto via
        // ChangeNotifierProxyProvider para que os widgets escutem
        // notifyListeners(). Reaproveita a instância entre rebuilds e só
        // recria se o ApiService (do AuthService) mudar de identidade.
        ChangeNotifierProxyProvider<AuthService, LogsProvider>(
          create: (context) =>
              LogsProvider(context.read<AuthService>().apiService),
          update: (_, authService, previous) =>
              previous ?? LogsProvider(authService.apiService),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (ctx, themeController, _) => MaterialApp(
          navigatorKey: _navKey,
          title: AppConstants.brandName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
          locale: const Locale('pt', 'BR'),
          theme: RecorpoTheme.light(),
          darkTheme: RecorpoTheme.dark(),
          themeMode: themeController.mode,
          home: _disclaimerAceito
              ? Consumer2<AuthService, AppLockService>(
                  builder: (context, authService, appLock, _) {
                    // Lote 32.5 — Gate de bloqueio na frente de tudo pra
                    // proteger dados de saúde quando o app volta do
                    // background após inatividade.
                    if (appLock.configurado && appLock.travado) {
                      return const AppLockScreen();
                    }
                    if (!authService.isAuthenticated) {
                      return const LoginPage();
                    }
                    // Lote 29 — Após login/registro, exibe o onboarding
                    // uma única vez. Usuário pode pular; a flag é
                    // persistida em SharedPreferences ao concluir/pular.
                    if (!_onboardingCompleto) {
                      return OnboardingScreen(
                          onConcluir: _onOnboardingConcluido);
                    }
                    return const DashboardPage();
                  },
                )
              : DisclaimerScreen(onAceito: _onDisclaimerAceito),
        ),
      ),
    );
  }
}

// ============================================================================
// LOGIN PAGE
// ============================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscureSenha = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authService = context.read<AuthService>();

    try {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        setState(() => errorMessage = 'Email e senha são obrigatórios');
        return;
      }

      setState(() => isLoading = true);

      await authService.login(
        email: emailController.text,
        senha: passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Lote 20 — Login social. `null` = cancelou; sucesso = navega pro
  // dashboard igual o login por email.
  void _handleLoginGoogle() async {
    final authService = context.read<AuthService>();
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final resultado = await authService.signInComGoogle();
      if (!mounted) return;
      if (resultado == null) {
        setState(() => isLoading = false);
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Cabeçalho / identidade =====
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF4A90D9),
                                AppColors.azulClinico,
                                Color(0xFF1E4E85),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.azulClinico
                                    .withValues(alpha: 0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.vaccines,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppColors.azulClinico,
                              Color(0xFF4A90D9),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            AppConstants.brandName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppConstants.appName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 2.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.appSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    // ===== Formulário =====
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 36),
                        Builder(builder: (context) {
                          // Lote 28 — Cores dos campos adaptativas ao tema.
                          // No dark o branco fixo ficava agressivo e o
                          // placeholder cinza sumia; agora usamos surface do
                          // ColorScheme e onSurface pro texto/ícones.
                          final ehDark = Theme.of(context).brightness ==
                              Brightness.dark;
                          final fill = ehDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white;
                          final onSurface =
                              Theme.of(context).colorScheme.onSurface;
                          final iconColor = onSurface.withValues(alpha: 0.7);
                          final borderColor = ehDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.1);
                          return Column(children: [
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: onSurface, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                    color:
                                        onSurface.withValues(alpha: 0.75)),
                                hintText: 'seu@email.com',
                                hintStyle: TextStyle(
                                    color:
                                        onSurface.withValues(alpha: 0.4)),
                                prefixIcon: Icon(Icons.mail_outline,
                                    color: iconColor),
                                filled: true,
                                fillColor: fill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscureSenha,
                              style: TextStyle(color: onSurface, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                labelStyle: TextStyle(
                                    color:
                                        onSurface.withValues(alpha: 0.75)),
                                hintText: '••••••••',
                                hintStyle: TextStyle(
                                    color:
                                        onSurface.withValues(alpha: 0.4)),
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: iconColor),
                                filled: true,
                                fillColor: fill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscureSenha
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: iconColor),
                                  tooltip: _obscureSenha
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: () => setState(
                                      () => _obscureSenha = !_obscureSenha),
                                ),
                              ),
                            ),
                          ]);
                        }),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.vermelhoAlerta
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.vermelhoAlerta),
                            ),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: AppColors.vermelhoAlerta,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azulClinico,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Divisor "ou"
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 12)),
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Lote 20 — Botão de login com Google.
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : _handleLoginGoogle,
                            icon: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            label: const Text(
                              'Continuar com Google',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RegisterPage()),
                              );
                            },
                            child: const Text('Não tem conta? Criar uma'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AvisoImportante(
                          corpo: AppConstants.disclaimerMedico
                              .replaceFirst('⚠️ AVISO IMPORTANTE', '')
                              .trim(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso regulatório com o título "AVISO IMPORTANTE" em vermelho negrito
/// pulsando (pisca suave, sem estrobo). Corpo centralizado.
class _AvisoImportante extends StatefulWidget {
  final String corpo;
  const _AvisoImportante({required this.corpo});

  @override
  State<_AvisoImportante> createState() => _AvisoImportanteState();
}

class _AvisoImportanteState extends State<_AvisoImportante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.vermelhoAlerta.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.vermelhoAlerta.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.2).animate(
              CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
            ),
            child: const Text(
              '⚠️ AVISO IMPORTANTE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.vermelhoAlerta,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.corpo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REGISTER PAGE
// ============================================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final dataNascimentoController = TextEditingController();
  DateTime? _dataNascimento;
  bool _obscureSenha = true;
  bool aceitoTermos = false;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime(agora.year - 30, agora.month, agora.day),
      firstDate: DateTime(1900),
      lastDate: agora,
      helpText: 'Selecione sua data de nascimento',
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) {
      setState(() {
        _dataNascimento = escolhida;
        final d = escolhida.day.toString().padLeft(2, '0');
        final m = escolhida.month.toString().padLeft(2, '0');
        dataNascimentoController.text = '$d/$m/${escolhida.year}';
      });
    }
  }

  /// ISO YYYY-MM-DD exigido pelo backend.
  String? get _dataNascimentoIso {
    final dt = _dataNascimento;
    if (dt == null) return null;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  Future<void> _abrirTermos() async {
    final aceitou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _TermosSheet(),
    );
    if (aceitou == true) {
      setState(() => aceitoTermos = true);
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dataNascimentoController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!aceitoTermos) {
      setState(() => errorMessage = 'Você deve aceitar os termos');
      return;
    }

    final nomeError = Validators.validateNome(nomeController.text);
    final emailError = Validators.validateEmail(emailController.text);
    final passwordError = Validators.validatePassword(passwordController.text);
    final dataIso = _dataNascimentoIso;
    final dataError = dataIso == null
        ? 'Selecione sua data de nascimento'
        : Validators.validateDataNascimento(dataIso);

    if (nomeError != null) {
      setState(() => errorMessage = nomeError);
      return;
    }
    if (emailError != null) {
      setState(() => errorMessage = emailError);
      return;
    }
    if (passwordError != null) {
      setState(() => errorMessage = passwordError);
      return;
    }
    if (dataError != null) {
      setState(() => errorMessage = dataError);
      return;
    }

    final authService = context.read<AuthService>();

    try {
      setState(() => isLoading = true);

      await authService.register(
        nome: nomeController.text,
        email: emailController.text,
        senha: passwordController.text,
        dataNascimento: dataIso!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conta criada! Faça login para continuar.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome completo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: _obscureSenha,
                decoration: InputDecoration(
                  labelText: 'Senha (mínimo 8 caracteres)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSenha
                        ? Icons.visibility_off
                        : Icons.visibility),
                    tooltip: _obscureSenha ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () =>
                        setState(() => _obscureSenha = !_obscureSenha),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dataNascimentoController,
                readOnly: true,
                onTap: _selecionarData,
                decoration: InputDecoration(
                  labelText: 'Data de nascimento',
                  hintText: 'DD/MM/AAAA',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _abrirTermos,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Icon(
                      aceitoTermos
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: aceitoTermos
                          ? AppColors.verdeConfirma
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aceitoTermos
                            ? 'Termos de uso e política de privacidade aceitos'
                            : 'Ler e aceitar os termos de uso e política de privacidade',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: aceitoTermos
                                  ? null
                                  : TextDecoration.underline,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.vermelhoAlerta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.vermelhoAlerta),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                        color: AppColors.vermelhoAlerta, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      aceitoTermos && !isLoading ? _handleRegister : null,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Criar conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD PAGE
// ============================================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogsProvider>().carregarDashboard();
    });
  }

  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.brandName),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Relatório para o médico',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      // extendBody deixa o conteúdo passar POR BAIXO da nav flutuante;
      // adicionamos padding-bottom no scroll da HomePage para não ficar
      // escondido atrás da pílula.
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          FloatingNavItem(icone: Icons.home_rounded, rotulo: 'Home'),
          FloatingNavItem(icone: Icons.history_rounded, rotulo: 'Histórico'),
          FloatingNavItem(icone: Icons.person_rounded, rotulo: 'Perfil'),
        ],
      ),
    );
  }
}

// ============================================================================
// HOME PAGE
// ============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EixoFarmacologico? _eixo;
  IdentidadeGenero? _genero;
  PerfilBackend? _perfil;
  bool _contextoCarregado = false;

  // Lote 30 — Estado do lembrete semanal da dose.
  bool _lembreteDoseHabilitado = false;
  int _lembreteDoseWeekday = DateTime.thursday;
  int _lembreteDoseHora = 9;
  int _lembreteDoseMinuto = 0;

  // Lote 32.1 — Health Connect (passos, sono, peso via balança smart).
  HealthResumoDia _health = HealthResumoDia.vazio;
  final _healthService = HealthConnectService();

  // Lote 32.4 — Alertas clínicos objetivos (sintoma persistente etc.).
  List<Map<String, dynamic>> _alertas = const [];

  @override
  void initState() {
    super.initState();
    _carregarContexto();
  }

  Future<void> _carregarContexto() async {
    // Eixo (local + rápido) e perfil (backend) em paralelo. Falhas no
    // perfil não bloqueiam o render: só afetam a exibição das metas.
    // Captura o service antes do primeiro await para evitar uso de
    // BuildContext em async gap.
    final auth = context.read<AuthService>();
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(ProfilePrefsKeys.eixoFarmacologico);
    final eixo = nome == null
        ? null
        : EixoFarmacologico.values
            .cast<EixoFarmacologico?>()
            .firstWhere((v) => v?.name == nome, orElse: () => null);
    final nomeGen = prefs.getString(ProfilePrefsKeys.identidadeGenero);
    final genero = nomeGen == null
        ? null
        : IdentidadeGenero.values
            .cast<IdentidadeGenero?>()
            .firstWhere((v) => v?.name == nomeGen, orElse: () => null);

    // Lote 30 — Lembrete semanal da dose.
    final lembreteHabilitado =
        prefs.getBool(ProfilePrefsKeys.doseReminderEnabled) ?? false;
    final lembreteWeekday =
        prefs.getInt(ProfilePrefsKeys.doseReminderWeekday) ??
            _lembreteDoseWeekday;
    final lembreteHora =
        prefs.getInt(ProfilePrefsKeys.doseReminderHour) ?? _lembreteDoseHora;
    final lembreteMinuto = prefs.getInt(ProfilePrefsKeys.doseReminderMinute) ??
        _lembreteDoseMinuto;

    PerfilBackend? perfil;
    try {
      final json = await auth.apiService.obterPerfil();
      final perfilJson = json['perfil'] as Map<String, dynamic>?;
      if (perfilJson != null) {
        perfil = PerfilBackend.fromJson(perfilJson);
      }
    } catch (_) {
      // Sem perfil ainda ou backend indisponível — segue sem metas.
    }

    // Lote 31 — Migração one-shot das prefs locais para o backend.
    // Roda uma única vez por instalação: se o backend ainda não conhece
    // eixo/identidade/sexo/última dose/meta de peso, sobe o que temos
    // em prefs. Idempotente e silencioso — em caso de erro, tenta na
    // próxima abertura porque a flag só é gravada em caso de sucesso.
    final jaMigrado =
        prefs.getBool(AppConstants.keyPerfilMigradoParaBackendV1) ?? false;
    if (!jaMigrado && perfil != null) {
      final ultimaDoseIso = prefs.getString(ProfilePrefsKeys.ultimaDoseIso);
      final sexoNome = prefs.getString(ProfilePrefsKeys.sexoBiologico);
      final metaPesoKg = prefs.getDouble(ProfilePrefsKeys.metaPesoKg);
      final precisaSubir = (perfil.eixoFarmacologico == null && eixo != null) ||
          (perfil.identidadeGenero == null && genero != null) ||
          (perfil.sexoBiologico == null && sexoNome != null) ||
          (perfil.ultimaDose == null && ultimaDoseIso != null) ||
          (perfil.metaPesoKg == null && metaPesoKg != null);
      if (precisaSubir) {
        try {
          await auth.apiService.salvarPerfil(
            declarouPrescricao: perfil.declarouPrescricao,
            eixoFarmacologico:
                perfil.eixoFarmacologico == null ? eixo?.name : null,
            identidadeGenero:
                perfil.identidadeGenero == null ? genero?.name : null,
            sexoBiologico:
                perfil.sexoBiologico == null ? sexoNome : null,
            ultimaDoseIso: perfil.ultimaDose == null
                ? ultimaDoseIso?.split('T').first
                : null,
            metaPesoKg: perfil.metaPesoKg == null ? metaPesoKg : null,
          );
          await prefs.setBool(
              AppConstants.keyPerfilMigradoParaBackendV1, true);
        } catch (_) {
          // Tenta de novo na próxima abertura.
        }
      } else {
        // Já não há mais nada pra migrar — marca como concluído.
        await prefs.setBool(
            AppConstants.keyPerfilMigradoParaBackendV1, true);
      }
    }

    // Lote 32.1 — Puxa passos, sono, peso e batimentos do Health
    // Connect. Silencioso: se o plugin/permissão falhar, seguimos
    // sem os dados. `temAutorizacao` evita pedir permissão em cada
    // abertura — só pedimos no primeiro uso via HealthHubScreen.
    HealthResumoDia healthResumo = HealthResumoDia.vazio;
    if (_healthService.suportado) {
      try {
        final autorizado = await _healthService.temAutorizacao();
        if (autorizado) {
          healthResumo = await _healthService.resumoDeHoje();
        }
      } catch (_) {
        // Plugin indisponível ou permissão negada — segue vazio.
      }
    }

    // Lote 32.4 — Puxa alertas objetivos do backend. Falha silenciosa
    // (banner só aparece quando temos dado).
    List<Map<String, dynamic>> alertas = const [];
    try {
      final resp = await auth.apiService.obterAlertas();
      alertas = ((resp['alertas'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      // Backend indisponível — dashboard segue sem banner.
    }

    if (!mounted) return;
    setState(() {
      _eixo = eixo;
      _genero = genero;
      _perfil = perfil;
      _lembreteDoseHabilitado = lembreteHabilitado;
      _lembreteDoseWeekday = lembreteWeekday;
      _lembreteDoseHora = lembreteHora;
      _lembreteDoseMinuto = lembreteMinuto;
      _health = healthResumo;
      _alertas = alertas;
      _contextoCarregado = true;
    });

    // Lote 32.4 — Dispara notificação semanal quando há alerta ativo,
    // sem interromper o boot. `_talvezNotificarAlertas` é idempotente
    // e respeita o próprio limitador (1× por semana).
    unawaited(_talvezNotificarAlertas(alertas));

    // Lote 30 — Se o usuário configurou lembrete e o app foi reinstalado
    // ou reiniciado, reagenda para garantir persistência entre boots.
    if (lembreteHabilitado && (eixo?.envolveMedicacao ?? false)) {
      await NotificationService().agendarDoseSemanal(
        weekday: lembreteWeekday,
        hour: lembreteHora,
        minute: lembreteMinuto,
        primeiroNome: (auth.nome ?? '').trim().split(' ').first,
        medicamento: perfil?.medicationNome,
      );
    }

    // Depois que perfil e logs estão carregados, sincronizamos o
    // widget de Água: (1) descarrega o que ele acumulou em background
    // no log do dia via backend, e (2) publica o novo total + a meta
    // para o widget exibir. Falhas são silenciosas — o app segue OK.
    await _sincronizarWidgetAgua();
  }

  Future<void> _sincronizarWidgetAgua() async {
    const service = WaterWidgetService();
    if (!service.suportado) return;

    final auth = context.read<AuthService>();
    final logs = context.read<LogsProvider>().logs;
    final agora = DateTime.now();

    // Localiza log de hoje (se existir) para saber o valor atual de água.
    final logHoje = logs.cast<dynamic>().firstWhere(
      (l) =>
          l != null &&
          l.data.year == agora.year &&
          l.data.month == agora.month &&
          l.data.day == agora.day,
      orElse: () => null,
    );
    final aguaBackend =
        logHoje == null ? 0 : (logHoje.aguaMl ?? 0) as int;

    // (1) Consolida pendente do widget no backend, se houver.
    final pendente = await service.lerEzerarPendente();
    var aguaConsolidada = aguaBackend;
    if (pendente > 0) {
      final novoTotal = aguaBackend + pendente;
      try {
        await auth.apiService.registrarLog(
          data: agora,
          aguaMl: novoTotal,
        );
        aguaConsolidada = novoTotal;
        // Recarrega o dashboard pra provider ficar coerente.
        if (mounted) {
          await context.read<LogsProvider>().carregarDashboard();
        }
      } catch (_) {
        // Sem rede — devolvemos o pendente pra próxima abertura.
        await HomeWidget.saveWidgetData<int>(
            WaterWidgetKeys.pendente, pendente);
        aguaConsolidada = aguaBackend + pendente; // ainda mostra
      }
    }

    // (2) Publica estado atualizado no widget (número + meta).
    final pesoParaMeta =
        (logHoje?.pesoKg as double?) ?? _perfil?.pesoInicialKg;
    final metaAguaMl = pesoParaMeta == null
        ? 0
        : (pesoParaMeta *
                (_perfil?.metaAguaMlKg ?? AppConstants.defaultMetaAguaMlkg))
            .round();
    await service.publicarEstado(
      hojeMl: aguaConsolidada,
      metaMl: metaAguaMl,
      hoje: agora,
    );

    // (3) Notificações locais (Lote 19). Pede permissão na primeira vez;
    // reagenda diárias com estado atualizado; celebra se streak fechou
    // marco. Tudo silencioso — sem UI extra.
    if (mounted) {
      await _atualizarNotificacoes(
        aguaHoje: aguaConsolidada,
        metaAgua: metaAguaMl,
        jaTeveLogHoje: logHoje != null,
      );
    }
  }

  Future<void> _atualizarNotificacoes({
    required int aguaHoje,
    required int metaAgua,
    required bool jaTeveLogHoje,
  }) async {
    final notif = NotificationService();
    if (!notif.suportado) return;

    final auth = context.read<AuthService>();
    final logs = context.read<LogsProvider>();
    final primeiroNome = (auth.nome ?? '').trim().split(' ').first;

    // Pede permissão só na primeira vez; ignora resposta se negada
    // (o app continua útil mesmo sem notificações).
    await notif.pedirPermissao();

    final abaixoDaMeta = metaAgua > 0 && aguaHoje < metaAgua;
    await notif.reagendarDiarias(
      primeiroNome: primeiroNome,
      hidratacaoAbaixoDaMeta: abaixoDaMeta,
      jaTeveLogHoje: jaTeveLogHoje,
    );

    // Celebração — dispara se hoje é marco de streak (3, 7, 30…) OU
    // rotaciona motivação. Uma vez por sessão para não spammar.
    if (!_celebrouNestaSessao) {
      _celebrouNestaSessao = true;
      await notif.celebrar(
        primeiroNome: primeiroNome,
        streakDias: logs.streak,
      );
    }
  }

  bool _celebrouNestaSessao = false;

  /// Lote 32.1 — Decide se deve mostrar o banner "importar peso auto".
  /// Regra: Health Connect tem peso registrado hoje (a partir das 0h) E
  /// o valor difere em ≥ 0.1 kg do último peso do app.
  bool _deveOfertarImportarPeso(double? pesoAppUltimo) {
    final pesoH = _health.pesoUltimoKg;
    final quando = _health.pesoUltimoEm;
    if (pesoH == null || quando == null) return false;
    final hoje = DateTime.now();
    final ehDeHoje = quando.year == hoje.year &&
        quando.month == hoje.month &&
        quando.day == hoje.day;
    if (!ehDeHoje) return false;
    if (pesoAppUltimo == null) return true;
    return (pesoH - pesoAppUltimo).abs() >= 0.1;
  }

  /// Lote 32.4 — Notificação semanal quando há alerta ativo. Respeita
  /// 1× por semana por tipo de alerta usando prefs; o banner do
  /// dashboard continua visível todos os dias enquanto persistir.
  Future<void> _talvezNotificarAlertas(
      List<Map<String, dynamic>> alertas) async {
    if (alertas.isEmpty) return;
    final notif = NotificationService();
    if (!notif.suportado) return;
    final auth = context.read<AuthService>();
    final primeiroNome = (auth.nome ?? '').trim().split(' ').first;
    final prefs = await SharedPreferences.getInstance();
    final agora = DateTime.now();
    for (final a in alertas) {
      final tipo = a['tipo'] as String? ?? 'desconhecido';
      final chave = 'alerta_notificado_$tipo';
      final ultimoIso = prefs.getString(chave);
      final ultimo = ultimoIso == null ? null : DateTime.tryParse(ultimoIso);
      final passouSemana =
          ultimo == null || agora.difference(ultimo).inDays >= 7;
      if (!passouSemana) continue;
      await notif.enviarAlertaSintomaPersistente(
        primeiroNome: primeiroNome,
        titulo: a['titulo'] as String? ?? 'Recorpo',
        descricao: a['descricao'] as String? ?? '',
      );
      await prefs.setString(chave, agora.toIso8601String());
    }
  }

  Future<void> _importarPesoDeHealth() async {
    final pesoH = _health.pesoUltimoKg;
    if (pesoH == null) return;
    try {
      await context.read<LogsProvider>().adicionarLog(
            data: DateTime.now(),
            pesoKg: pesoH,
            alimentos: 'Peso: ${pesoH.toStringAsFixed(1)} kg @ Balança smart',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Peso ${pesoH.toStringAsFixed(1)} kg importado da balança smart.')),
      );
      await _carregarContexto();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao importar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LogsProvider>(
      builder: (context, logsProvider, _) {
        if (logsProvider.isLoading || !_contextoCarregado) {
          return const Center(child: CircularProgressIndicator());
        }

        // Peso mais recente reportado nos logs (topo da lista, se ordenada
        // por data desc). O comparador anterior é o segundo com peso.
        final logsComPeso =
            logsProvider.logs.where((l) => l.pesoKg != null).toList();
        final pesoAtual =
            logsComPeso.isNotEmpty ? logsComPeso.first.pesoKg : null;
        final pesoAnterior =
            logsComPeso.length > 1 ? logsComPeso[1].pesoKg : null;

        // Metas do dia: peso × (metas do perfil ou defaults do PRD).
        // Fallback para o peso do perfil (pesoInicialKg) quando ainda
        // não há nenhum log com peso.
        final pesoParaMeta = pesoAtual ?? _perfil?.pesoInicialKg;
        final metaProteinaG = pesoParaMeta == null
            ? null
            : pesoParaMeta *
                (_perfil?.metaProteinaGkg ??
                    AppConstants.defaultMetaProteinaGkg);
        final metaAguaMl = pesoParaMeta == null
            ? null
            : pesoParaMeta *
                (_perfil?.metaAguaMlKg ?? AppConstants.defaultMetaAguaMlkg);

        // Consumo de hoje: primeiro log cuja data == hoje. Se não há log
        // hoje, mostra 0 (com barra em azul clínico), não `null`.
        final hoje = DateTime.now();
        final logHoje = logsProvider.logs
            .cast<dynamic>()
            .firstWhere(
                (l) =>
                    l != null &&
                    l.data.year == hoje.year &&
                    l.data.month == hoje.month &&
                    l.data.day == hoje.day,
                orElse: () => null);
        final consumidoProteinaG =
            logHoje == null ? 0.0 : (logHoje.proteinaG ?? 0).toDouble();
        final consumidoAguaMl =
            logHoje == null ? 0.0 : (logHoje.aguaMl ?? 0).toDouble();

        // Lote 26 — Métricas para os EixoCards do hero.
        final logsDeHoje = logsProvider.logs
            .cast<dynamic>()
            .where((l) =>
                l != null &&
                l.data.year == hoje.year &&
                l.data.month == hoje.month &&
                l.data.day == hoje.day)
            .toList();
        final refeicoesHoje = logsDeHoje
            .where((l) =>
                (l.alimentos as String?)?.trim().isNotEmpty ?? false)
            .length;
        var sintomasHoje = 0;
        for (final l in logsDeHoje) {
          final efeitos = l.efeitosColaterais as String?;
          if (efeitos == null || efeitos.isEmpty) continue;
          try {
            final j = jsonDecode(efeitos);
            if (j is Map && j['sintomas'] is List) {
              sintomasHoje += (j['sintomas'] as List).length;
            }
          } catch (_) {}
        }
        final deltaPeso = (pesoAtual != null && pesoAnterior != null)
            ? pesoAtual - pesoAnterior
            : null;
        final aguaPct = (metaAguaMl != null && metaAguaMl > 0)
            ? (consumidoAguaMl / metaAguaMl * 100).clamp(0, 999).round()
            : null;

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              logsProvider.carregarDashboard(),
              _carregarContexto(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // padding-bottom generoso: a FloatingNavBar fica sobre o
            // conteúdo (extendBody), então o último card precisa desse
            // espaço para não ficar coberto.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) Saudação personalizada — hora do dia + primeiro nome +
                //    concordância de gênero.
                _SaudacaoHumana(genero: _genero),
                const SizedBox(height: 12),
                // 2) Dica do dia — pool com concordância de gênero,
                //    determinística por data.
                _DicaDoDiaHumana(genero: _genero),
                const SizedBox(height: 16),
                // 3) Foco do dia (Blindagem Muscular + eixo)
                _FocoDoDia(eixo: _eixo),
                const SizedBox(height: 16),
                // 3a) Lote 32.1 — Banner "importar peso da balança smart"
                //     Aparece só quando o Health Connect tem um peso mais
                //     recente que o último log do app (delta > 24h ou peso
                //     diferente do último).
                if (_deveOfertarImportarPeso(pesoAtual))
                  _BannerImportarPeso(
                    pesoDeHealth: _health.pesoUltimoKg!,
                    quando: _health.pesoUltimoEm!,
                    onImportar: () => _importarPesoDeHealth(),
                  ),
                if (_deveOfertarImportarPeso(pesoAtual))
                  const SizedBox(height: 12),
                // 3b) Lote 32.4 — Alertas clínicos objetivos (sintoma
                //     persistente etc.). Renderiza no máximo 1 banner —
                //     se houver múltiplos, mostra o primeiro (o backend
                //     ordena pela severidade / gravidade).
                if (_alertas.isNotEmpty) ...[
                  _BannerAlertaClinico(
                    alerta: _alertas.first,
                    onAbrir: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PreConsultaScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // 3b) Lote 30 — Lembrete semanal da dose. Só aparece se
                //     o eixo envolve medicação (não faz sentido em
                //     recomposição natural).
                if (_eixo?.envolveMedicacao ?? false) ...[
                  _LembreteDoseCard(
                    habilitado: _lembreteDoseHabilitado,
                    weekday: _lembreteDoseWeekday,
                    hora: _lembreteDoseHora,
                    minuto: _lembreteDoseMinuto,
                    nomeMedicamento: _perfil?.medicationNome,
                    onAbrir: () async {
                      final resultado = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => DoseReminderScreen(
                            nomeMedicamento: _perfil?.medicationNome,
                          ),
                        ),
                      );
                      if (resultado == true) await _carregarContexto();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Lote 32.2 — Preparar consulta. Só aparece quando o
                // usuário já tem ≥7 dias de registros — antes disso o
                // resumo fica ralo e a experiência decepciona.
                if (logsProvider.logs.length >= 7) ...[
                  _CardPrepararConsulta(
                    onAbrir: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PreConsultaScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // 4) HERO — grid 2×2 de EixoCards (Lote 26)
                //    Cada card mostra o estado real do dia e leva pra
                //    ação/detalhe. Visual estilo Samsung Health.
                Row(
                  children: [
                    Expanded(
                      child: Consumer<PremiumService>(
                        builder: (ctx, premium, _) => FutureBuilder<int?>(
                          future: FeatureUsageService().restante(
                              Feature.cameraRefeicao,
                              premium: premium.isPremium),
                          builder: (ctx, snap) {
                            final restante = snap.data;
                            String rodape;
                            if (premium.isPremium) {
                              rodape = 'Toque para escanear';
                            } else if (restante == null) {
                              rodape = 'Toque para escanear';
                            } else if (restante == 0) {
                              rodape = 'Grátis usado · toque';
                            } else {
                              rodape =
                                  'Grátis: $restante ${restante == 1 ? "restante" : "restantes"}';
                            }
                            return EixoCard(
                              eixo: EixoRecorpo.refeicao,
                              titulo: 'Refeições',
                              valor:
                                  refeicoesHoje == 0 ? '—' : '$refeicoesHoje',
                              subtitulo: refeicoesHoje == 0
                                  ? 'Nenhuma hoje'
                                  : refeicoesHoje == 1
                                      ? '1 registrada hoje'
                                      : '$refeicoesHoje registradas hoje',
                              rodape: rodape,
                              onTap: () => abrirFluxoRefeicao(context),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EixoCard(
                        eixo: EixoRecorpo.agua,
                        titulo: 'Água',
                        valor: consumidoAguaMl == 0
                            ? '0'
                            : '${(consumidoAguaMl / 1000).toStringAsFixed(1)}L',
                        subtitulo: aguaPct == null
                            ? 'Sem meta'
                            : '$aguaPct% da meta',
                        rodape: 'Toque para adicionar',
                        onTap: () => mostrarWaterQuickSheet(
                          context,
                          aguaAtualMl: consumidoAguaMl.round(),
                          metaAguaMl: metaAguaMl?.round(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: EixoCard(
                        eixo: EixoRecorpo.peso,
                        titulo: 'Peso',
                        valor: pesoAtual == null
                            ? '—'
                            : pesoAtual.toStringAsFixed(1),
                        subtitulo: pesoAtual == null
                            ? 'Sem registro'
                            : deltaPeso == null
                                ? 'kg (primeiro registro)'
                                : deltaPeso < 0
                                    ? 'kg · ${deltaPeso.toStringAsFixed(1)} vs último'
                                    : 'kg · +${deltaPeso.toStringAsFixed(1)} vs último',
                        rodape: 'Toque para registrar',
                        onTap: () => mostrarWeightQuickSheet(
                          context,
                          pesoAnteriorKg: pesoAtual,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EixoCard(
                        eixo: EixoRecorpo.sintomas,
                        titulo: 'Sintomas',
                        valor: sintomasHoje == 0 ? 'OK' : '$sintomasHoje',
                        subtitulo: sintomasHoje == 0
                            ? 'Nada registrado hoje'
                            : sintomasHoje == 1
                                ? '1 registrado hoje'
                                : '$sintomasHoje registrados hoje',
                        rodape: 'Como você está?',
                        onTap: () => abrirSymptomsSheet(context),
                      ),
                    ),
                  ],
                ),
                // Lote 32.1 — 3ª linha só quando o Health Connect estiver
                // com dados. Sem push tributário: usuário sem relógio nem
                // percebe que existe (limpa o dashboard).
                if (_health.temDados) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: EixoCard(
                          eixo: EixoRecorpo.movimento,
                          titulo: 'Movimento',
                          valor: _health.passos == null
                              ? '—'
                              : _health.passos! >= 1000
                                  ? '${(_health.passos! / 1000).toStringAsFixed(1)}k'
                                  : '${_health.passos}',
                          subtitulo: _health.passos == null
                              ? 'Sem passos hoje'
                              : _health.passos == 1
                                  ? '1 passo'
                                  : '${_health.passos} passos',
                          rodape: _health.kcalAtivas == null
                              ? 'Do seu relógio'
                              : '${_health.kcalAtivas!.round()} kcal ativas',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HealthHubScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardSono(sonoMinutos: _health.sonoMinutos),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                // 5) Consistência — streak + score
                Row(
                  children: [
                    Expanded(
                      child: StreakBadge(
                        days: logsProvider.streak,
                        title: 'Streak',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ScoreCard(
                        score: logsProvider.scoreToday,
                        label: 'Score hoje',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 5) CTA principal — Registrar de hoje sobe pra posição
                //    de destaque (era no fim; agora vem antes dos dados)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LogDailyPage()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar de hoje',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulClinico,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 6) Dados de composição
                RecompositionCard(
                  pesoAtualKg: pesoAtual,
                  pesoAnteriorKg: pesoAnterior,
                ),
                const SizedBox(height: 16),
                // 7) Macros
                MacrosCard(
                  metaProteinaG: metaProteinaG,
                  metaAguaMl: metaAguaMl,
                  consumidoProteinaG: consumidoProteinaG,
                  consumidoAguaMl: consumidoAguaMl,
                ),
                const SizedBox(height: 16),
                // 8) Ajuste de esforço
                EffortPreviewCard(
                  eixo: _eixo,
                  onAbrir: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EffortScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                // 9) Scanners (ferramentas mais avançadas)
                _ScannersRow(),
                const SizedBox(height: 16),
                // 10) Análise longa — gráfico de 28 dias
                if (logsProvider.scores.isNotEmpty)
                  MetricChart(
                    scores: logsProvider.scores
                        .take(28)
                        .map((s) => s.score)
                        .toList(),
                    title: 'Scores últimos 28 dias',
                    subtitle:
                        'Progressão de conformidade (proteína, hidratação, registro)',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card de destaque com o foco do dia — texto fixo "BLINDAGEM MUSCULAR"
/// e o eixo farmacológico atual do perfil (ou CTA quando não configurado).
/// Saudação humanizada — hora do dia + primeiro nome + concordância
/// com o gênero. Conteúdo em `services/greeting_service.dart`.
class _SaudacaoHumana extends StatelessWidget {
  final IdentidadeGenero? genero;
  const _SaudacaoHumana({required this.genero});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final saudacao = const GreetingService().gerar(
      nomeCompleto: auth.nome,
      genero: genero,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(saudacao.titulo,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(saudacao.subtitulo,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
        ],
      ),
    );
  }
}

/// Dica do dia — usa o pool humanizado com concordância de gênero e
/// sorteio determinístico por data.
class _DicaDoDiaHumana extends StatelessWidget {
  final IdentidadeGenero? genero;
  const _DicaDoDiaHumana({required this.genero});

  @override
  Widget build(BuildContext context) {
    final dica = const DailyTipService().dicaDoDia(genero: genero);
    return Card(
      elevation: 0,
      color: AppColors.verdeConfirma.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.verdeConfirma.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dica.categoria.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dica.categoria.rotulo.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.verdeConfirma)),
                  const SizedBox(height: 4),
                  Text(
                    dica.texto,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lote 21 + 25 + 27 — Fluxo completo de escanear refeição.
/// Extraído para top-level para poder ser reusado (EixoCard do Hero + botão
/// da linha _ScannersRow). Lote 27 acrescentou o gate de quota Free:
/// se o usuário Grátis passou de 3 fotos no dia, mostra o
/// QuotaExceededSheet ofertando Premium em vez de abrir a câmera.
Future<void> abrirFluxoRefeicao(BuildContext context) async {
  final premium = context.read<PremiumService>();
  final uso = FeatureUsageService();
  final podeUsar = await uso.podeConsumir(
    Feature.cameraRefeicao,
    premium: premium.isPremium,
  );

  if (!context.mounted) return;
  if (!podeUsar) {
    final quota = FeaturePolicy.quotaFree(Feature.cameraRefeicao)!;
    await mostrarQuotaExcedida(
      context,
      feature: Feature.cameraRefeicao,
      eixo: EixoRecorpo.refeicao,
      tituloFeature: 'escanear refeição',
      limite: quota.limite,
      periodoLabel: 'hoje',
    );
    return;
  }

  final foto = await Navigator.of(context).push<XFile?>(
    MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
  );
  if (foto == null || !context.mounted) return;
  // Só conta o uso depois que a câmera efetivamente retornou uma foto —
  // cancelar antes de tirar não gasta cota.
  await uso.incrementar(Feature.cameraRefeicao, premium: premium.isPremium);

  if (!context.mounted) return;
  final descricao = await Navigator.of(context).push<String?>(
    MaterialPageRoute(builder: (_) => MealResultScreen(foto: foto)),
  );
  if (!context.mounted || descricao == null) return;
  Future.delayed(const Duration(milliseconds: 500), () {
    if (!context.mounted) return;
    abrirSymptomsSheet(context,
        contexto: descricao.isEmpty ? null : 'Após: $descricao');
  });
}

/// Dois botões de scanner lado a lado: refeição (câmera do Lote 9) e
/// prescrição (OCR do Lote 10). Ambos abrem tela cheia.
class _ScannersRow extends StatelessWidget {
  void _abrirPrescricao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DietScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estilo = OutlinedButton.styleFrom(
      foregroundColor: AppColors.azulClinico,
      side: const BorderSide(color: AppColors.azulClinico, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => abrirFluxoRefeicao(context),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Refeição',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: estilo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _abrirPrescricao(context),
            icon: const Icon(Icons.document_scanner_outlined, size: 18),
            label: const Text('Prescrição',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: estilo,
          ),
        ),
      ],
    );
  }
}

/// Lote 32.4 — Banner de alerta clínico objetivo. Nunca prescreve —
/// só descreve o padrão observado e convida a abrir a pré-consulta.
class _BannerAlertaClinico extends StatelessWidget {
  final Map<String, dynamic> alerta;
  final VoidCallback onAbrir;
  const _BannerAlertaClinico({required this.alerta, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
      onTap: onAbrir,
      child: Container(
        padding: const EdgeInsets.all(RecorpoSpacing.md),
        decoration: BoxDecoration(
          color: RecorpoColors.eixoSintomas.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          border: Border.all(
            color: RecorpoColors.eixoSintomas.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RecorpoGradients.sintomas,
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusSm),
              ),
              child:
                  const Icon(Icons.medical_information_outlined,
                      color: Colors.white, size: 22),
            ),
            const SizedBox(width: RecorpoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alerta['titulo'] as String? ?? 'Alerta',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(alerta['descricao'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: scheme.onSurface.withValues(alpha: 0.75))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        (alerta['cta'] as String?) ??
                            'Ver detalhes na pré-consulta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: RecorpoColors.eixoSintomas,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: RecorpoColors.eixoSintomas),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lote 32.2 — Card que abre a tela "Preparar consulta". Fica no
/// dashboard só depois de 7+ dias registrados (senão o resumo é ralo).
class _CardPrepararConsulta extends StatelessWidget {
  final VoidCallback onAbrir;
  const _CardPrepararConsulta({required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
      onTap: onAbrir,
      child: Container(
        padding: const EdgeInsets.all(RecorpoSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              RecorpoColors.confirma.withValues(alpha: 0.14),
              RecorpoColors.confirma.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          border: Border.all(
            color: RecorpoColors.confirma.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: RecorpoColors.confirma,
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusSm),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: RecorpoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preparar minha próxima consulta',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    'Resumo objetivo + perguntas curadas.',
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

/// Lote 32.1 — Banner que oferece importar o último peso lido do
/// Health Connect (tipicamente vindo de uma balança smart) para o
/// log do app. Reduz atrito: quem se pesa em balança Xiaomi/Withings
/// não precisa redigitar o valor.
class _BannerImportarPeso extends StatelessWidget {
  final double pesoDeHealth;
  final DateTime quando;
  final VoidCallback onImportar;

  const _BannerImportarPeso({
    required this.pesoDeHealth,
    required this.quando,
    required this.onImportar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horaFmt =
        '${quando.hour.toString().padLeft(2, '0')}:${quando.minute.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
      onTap: onImportar,
      child: Container(
        padding: const EdgeInsets.all(RecorpoSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              RecorpoColors.eixoPeso.withValues(alpha: 0.16),
              RecorpoColors.eixoPeso.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          border: Border.all(
            color: RecorpoColors.eixoPeso.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RecorpoGradients.peso,
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusSm),
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: RecorpoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sua balança smart marcou ${pesoDeHealth.toStringAsFixed(1)} kg',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Registrado às $horaFmt · toque para importar.',
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

/// Lote 32.1 — Card de sono do dashboard. Recebe minutos totais da
/// sessão de sono anterior (do Health Connect) e apresenta em h/min +
/// avaliação simples (curto/bom/longo) baseada em faixas OMS 7-9h.
class _CardSono extends StatelessWidget {
  final int? sonoMinutos;
  const _CardSono({required this.sonoMinutos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ehDark = Theme.of(context).brightness == Brightness.dark;

    final min = sonoMinutos;
    final valor = min == null
        ? '—'
        : min < 60
            ? '${min}m'
            : '${(min / 60).floor()}h${(min % 60).toString().padLeft(2, '0')}';
    final subtitulo = min == null
        ? 'Sem dado do relógio'
        : min < 6 * 60
            ? 'Curto (<6h)'
            : min > 9 * 60
                ? 'Longo (>9h)'
                : 'Dentro da faixa OMS';
    final rodape = min == null ? 'Conecte o Health Connect' : 'Ontem à noite';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ehDark
            ? RecorpoColors.darkSurface
            : RecorpoColors.lightSurface,
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusXl),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade400,
                  Colors.indigo.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
            ),
            child: const Icon(Icons.bedtime_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text('Sono',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.65))),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  height: 1)),
          const SizedBox(height: 8),
          Text(subtitulo,
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          Text(rodape,
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

/// Lote 30 — Card de acesso ao lembrete semanal da dose. Aparece só
/// quando o eixo envolve medicação. Sem configuração, mostra CTA de
/// ativar; com configuração, mostra próximo dia/horário.
class _LembreteDoseCard extends StatelessWidget {
  final bool habilitado;
  final int weekday;
  final int hora;
  final int minuto;
  final String? nomeMedicamento;
  final VoidCallback onAbrir;

  const _LembreteDoseCard({
    required this.habilitado,
    required this.weekday,
    required this.hora,
    required this.minuto,
    required this.nomeMedicamento,
    required this.onAbrir,
  });

  static const _diaLongo = <int, String>{
    DateTime.monday: 'Segunda',
    DateTime.tuesday: 'Terça',
    DateTime.wednesday: 'Quarta',
    DateTime.thursday: 'Quinta',
    DateTime.friday: 'Sexta',
    DateTime.saturday: 'Sábado',
    DateTime.sunday: 'Domingo',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horaFmt =
        '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
    final subtitulo = habilitado
        ? '${_diaLongo[weekday]} às $horaFmt · alerta na véspera'
        : 'Toque para receber alertas na véspera e no dia';
    final rotulo = habilitado ? 'Lembrete ativo' : 'Ativar lembrete da dose';

    return InkWell(
      borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
      onTap: onAbrir,
      child: Container(
        padding: const EdgeInsets.all(RecorpoSpacing.md),
        decoration: BoxDecoration(
          color: habilitado
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surface,
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          border: Border.all(
            color: habilitado
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RecorpoGradients.primary,
                borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
              ),
              child: Icon(
                habilitado
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: RecorpoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rotulo,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocoDoDia extends StatelessWidget {
  final EixoFarmacologico? eixo;
  const _FocoDoDia({required this.eixo});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.azulClinico.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.azulClinico.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.azulClinico, size: 20),
                const SizedBox(width: 8),
                Text('FOCO DO DIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.azulClinico,
                      letterSpacing: 2.0,
                    )),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Blindagem Muscular',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (eixo != null)
              Row(
                children: [
                  const Icon(Icons.science_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Eixo: ${eixo!.label}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Configure sua matriz metabólica na aba Perfil para '
                'personalizar o acompanhamento.',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOG DAILY PAGE
// ============================================================================

class LogDailyPage extends StatefulWidget {
  const LogDailyPage({Key? key}) : super(key: key);

  @override
  State<LogDailyPage> createState() => _LogDailyPageState();
}

class _LogDailyPageState extends State<LogDailyPage> {
  final pesoController = TextEditingController();
  final proteinaController = TextEditingController();
  final aguaController = TextEditingController();
  final alimentosController = TextEditingController();
  bool doseAplicada = false;
  bool isLoading = false;

  @override
  void dispose() {
    pesoController.dispose();
    proteinaController.dispose();
    aguaController.dispose();
    alimentosController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final logsProvider = context.read<LogsProvider>();

    try {
      setState(() => isLoading = true);

      await logsProvider.adicionarLog(
        data: DateTime.now(),
        pesoKg: pesoController.text.trim().isNotEmpty
            ? double.tryParse(pesoController.text.trim().replaceAll(',', '.'))
            : null,
        proteinaG: proteinaController.text.trim().isNotEmpty
            ? int.tryParse(proteinaController.text.trim())
            : null,
        aguaMl: aguaController.text.trim().isNotEmpty
            ? int.tryParse(aguaController.text.trim())
            : null,
        alimentos:
            alimentosController.text.isEmpty ? null : alimentosController.text,
        doseAplicada: doseAplicada,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Registro salvo com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar de hoje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                hintText: '98.5',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: proteinaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Proteína (g)',
                hintText: '120',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aguaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Água (ml)',
                hintText: '3000',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alimentosController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alimentos/observações',
                hintText: 'Ex: frango, brócolis, arroz...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Dose aplicada hoje?'),
              value: doseAplicada,
              onChanged: (v) => setState(() => doseAplicada = v ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSave,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Salvar registro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HISTORY PAGE
// ============================================================================

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogsProvider>().carregarLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LogsProvider>(
      builder: (context, logsProvider, _) {
        if (logsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (logsProvider.logs.isEmpty) {
          return const Center(
            child: Text('Nenhum registro encontrado'),
          );
        }

        return ListView.builder(
          // Espaço no fim para a FloatingNavBar (Lote 14) não cobrir o
          // último card do histórico.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: logsProvider.logs.length,
          itemBuilder: (context, index) {
            final log = logsProvider.logs[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(log.data),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (log.pesoKg != null &&
                            log.proteinaG != null &&
                            log.aguaMl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.verdeConfirma.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '✅ Completo',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '⚠️ Incompleto',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📊 Peso: ${log.pesoKg ?? "---"} kg | 🥚 Proteína: ${log.proteinaG ?? "---"}g | 💧 Água: ${log.aguaMl ?? "---"}ml',
                    ),
                    if (log.alimentos != null) ...[
                      const SizedBox(height: 8),
                      Text('🍽️ ${log.alimentos}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// PROFILE PAGE
// ============================================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const ProfileConfigScreen();
}

// ============================================================================
// TERMOS DE USO — leitura obrigatória com rolagem até o fim
// ============================================================================

class _TermosSheet extends StatefulWidget {
  const _TermosSheet();

  @override
  State<_TermosSheet> createState() => _TermosSheetState();
}

class _TermosSheetState extends State<_TermosSheet> {
  final _scroll = ScrollController();
  bool _leuTudo = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_leuTudo &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 24) {
        setState(() => _leuTudo = true);
      }
    });
    // Conteúdo curto que não rola: libera após o primeiro frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients &&
          _scroll.position.maxScrollExtent <= 0 &&
          !_leuTudo) {
        setState(() => _leuTudo = true);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Termos de Uso e Privacidade',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                _leuTudo
                    ? 'Você chegou ao fim. Escolha abaixo.'
                    : 'Role até o final para habilitar a escolha.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 20),
              Expanded(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: const Text(AppConstants.termosLegaisTexto,
                        style: TextStyle(fontSize: 13, height: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _leuTudo
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: const Text('Aceito'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
