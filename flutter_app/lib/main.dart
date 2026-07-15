import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ProxyProvider<AuthService, LogsProvider>(
          update: (_, authService, __) => LogsProvider(authService.apiService),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
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
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.isAuthenticated
                ? const DashboardPage()
                : const LoginPage();
          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                AppConstants.appSubtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'seu@email.com',
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
                  labelText: 'Senha',
                  hintText: '••••••••',
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
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
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
                      : const Text('Entrar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text('Não tem conta? Criar uma'),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: const Text(
                  AppConstants.disclaimerMedico,
                  style: TextStyle(fontSize: 11),
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
                      color: aceitoTermos ? Colors.green : Colors.grey,
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: aceitoTermos && !isLoading ? _handleRegister : null,
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
        title: const Text(AppConstants.appName),
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
                      const Text('1x/semana',
                          style: TextStyle(fontSize: 12)),
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
                  scores: logsProvider.scores
                      .take(28)
                      .map((s) => s.score)
                      .toList(),
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
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.amber.withOpacity(0.1),
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
        alimentos: alimentosController.text.isEmpty
            ? null
            : alimentosController.text,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: proteinaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Proteína (g)',
                hintText: '120',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aguaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Água (ml)',
                hintText: '3000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alimentosController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alimentos/observações',
                hintText: 'Ex: frango, brócolis, arroz...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        if (log.pesoKg != null && log.proteinaG != null && log.aguaMl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
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
                              color: Colors.orange.withOpacity(0.2),
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
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
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
                      const CircleAvatar(
                          radius: 40, child: Icon(Icons.person, size: 40)),
                      const SizedBox(height: 16),
                      Text(
                        authService.nome ?? 'Usuário',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authService.email ?? 'email@example.com',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Privacidade e termos'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Sobre'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ℹ️ Versão 0.1.0 - Beta\n\nApp em desenvolvimento. '
                  'Seus dados são protegidos conforme LGPD.',
                  style: TextStyle(fontSize: 12),
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

  static const String _texto = '''
TERMOS DE USO E POLÍTICA DE PRIVACIDADE
Assistente de Caneta — versão 0.1.0 (beta)

1. NATUREZA DO APLICATIVO
Este aplicativo é uma ferramenta educacional de registro e acompanhamento de conformidade para pessoas em tratamento com medicamentos da classe GLP-1/GIP. Ele NÃO fornece diagnóstico, NÃO substitui a orientação de profissionais de saúde e NÃO é um dispositivo médico.

2. USO PERMITIDO
2.1. O uso é permitido apenas para maiores de 18 anos.
2.2. Você é responsável pela veracidade dos dados que registra.
2.3. As informações educativas exibidas são reproduções de fontes oficiais (bulas Anvisa, ABESO, Ministério da Saúde, ADA), sempre citadas.

3. DADOS E PRIVACIDADE (LGPD — Lei 13.709/2018)
3.1. Seus dados de saúde são dados sensíveis e tratados com base no seu consentimento (art. 11).
3.2. Os dados são criptografados em trânsito (HTTPS) e sensíveis são cifrados no servidor.
3.3. Você pode, a qualquer momento: acessar, corrigir, exportar e solicitar a exclusão dos seus dados.
3.4. A exclusão remove sua conta e agenda a eliminação definitiva dos dados em até 30 dias.
3.5. Não vendemos nem compartilhamos seus dados com terceiros para fins de marketing.

4. LIMITAÇÃO DE RESPONSABILIDADE
4.1. As decisões sobre sua medicação, dose e tratamento devem ser sempre tomadas com seu médico.
4.2. O aplicativo não se responsabiliza por decisões tomadas exclusivamente com base nos registros ou alertas exibidos.

5. SEGURANÇA
5.1. Mantenha sua senha em sigilo.
5.2. Em caso de suspeita de acesso indevido, altere sua senha.

6. ALTERAÇÕES
Estes termos podem ser atualizados. Mudanças relevantes serão comunicadas no aplicativo.

7. CONTATO
Dúvidas sobre privacidade e seus direitos podem ser encaminhadas ao controlador dos dados pelo canal de suporte informado no aplicativo.

Ao tocar em "Aceito", você declara ter lido e concordado com os Termos de Uso e a Política de Privacidade acima, e consente com o tratamento dos seus dados de saúde para a finalidade de acompanhamento de conformidade.
''';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_leuTudo &&
          _scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 24) {
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
                    child: const Text(_texto, style: TextStyle(fontSize: 13, height: 1.5)),
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
