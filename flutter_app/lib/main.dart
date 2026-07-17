import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/profile_config_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/logs_provider.dart';
import 'widgets/score_card.dart';
import 'widgets/streak_badge.dart';
import 'widgets/metric_chart.dart';
import 'utils/constants.dart';
import 'utils/validators.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final disclaimerAceito =
      prefs.getBool(AppConstants.keyDisclaimerAceito) ?? false;

  runApp(MyApp(
    authService: authService,
    disclaimerAceitoInicial: disclaimerAceito,
  ));
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  final bool disclaimerAceitoInicial;

  const MyApp({
    super.key,
    required this.authService,
    required this.disclaimerAceitoInicial,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _disclaimerAceito;

  @override
  void initState() {
    super.initState();
    _disclaimerAceito = widget.disclaimerAceitoInicial;
  }

  void _onDisclaimerAceito() {
    setState(() => _disclaimerAceito = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: widget.authService),
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
      child: MaterialApp(
        title: AppConstants.brandName,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        locale: const Locale('pt', 'BR'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.azulClinico,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.fundoFrio,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.azulClinico,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        home: _disclaimerAceito
            ? Consumer<AuthService>(
                builder: (context, authService, _) {
                  return authService.isAuthenticated
                      ? const DashboardPage()
                      : const LoginPage();
                },
              )
            : DisclaimerScreen(onAceito: _onDisclaimerAceito),
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
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'seu@email.com',
                            prefixIcon: const Icon(Icons.mail_outline),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureSenha,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureSenha
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              tooltip: _obscureSenha
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              onPressed: () => setState(
                                  () => _obscureSenha = !_obscureSenha),
                            ),
                          ),
                        ),
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
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HOME PAGE
// ============================================================================

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LogsProvider>(
      builder: (context, logsProvider, _) {
        if (logsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Medicação atual',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Mounjaro (10mg)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('1x/semana', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              if (logsProvider.scores.isNotEmpty)
                MetricChart(
                  scores:
                      logsProvider.scores.take(28).map((s) => s.score).toList(),
                  title: 'Scores últimos 28 dias',
                  subtitle:
                      'Progressão de conformidade (proteína, hidratação, registro)',
                ),
              const SizedBox(height: 24),
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
                  label: const Text('Registrar de hoje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulClinico,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.amber.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('💡 Dica do dia',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(
                        'Bula Mounjaro recomenda: beba 2-3 litros de água por dia para evitar desidratação. '
                        'Continue hidratado! 🌊',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.all(16),
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
