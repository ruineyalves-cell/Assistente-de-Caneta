import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

import '../models/patient_profile.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import '../services/premium_service.dart';
import '../services/theme_controller.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'app_lock_setup_screen.dart';
import 'meus_dados_screen.dart';
import 'paywall_screen.dart';

/// Tela do Perfil / Matriz Metabólica (Lote 5).
///
/// Consolida identidade (gênero, sexo biológico), eixo farmacológico,
/// data da última dose, medicação, dosagem, peso e altura. Persistência
/// híbrida:
/// * campos que o backend já suporta → `PUT /api/pacientes/perfil`;
/// * campos ainda não modelados no backend → `shared_preferences` (ver
///   [ProfilePrefsKeys]).
class ProfileConfigScreen extends StatefulWidget {
  const ProfileConfigScreen({super.key});

  @override
  State<ProfileConfigScreen> createState() => _ProfileConfigScreenState();
}

class _ProfileConfigScreenState extends State<ProfileConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  String? _erroCarregamento;
  String? _mensagemSalvamento;
  bool _sucessoSalvamento = false;

  // Backend
  bool _declarouPrescricao = false;
  List<Map<String, dynamic>> _medicacoes = const [];
  int? _medicacaoIdSelecionada;

  // Local (shared_preferences)
  IdentidadeGenero? _genero;
  SexoBiologico? _sexo;
  EixoFarmacologico? _eixo;
  DateTime? _ultimaDose;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    final auth = context.read<AuthService>();
    try {
      // Local primeiro (rápido, offline).
      final prefs = await SharedPreferences.getInstance();
      _genero = _enumDe<IdentidadeGenero>(
          prefs.getString(ProfilePrefsKeys.identidadeGenero),
          IdentidadeGenero.values);
      _sexo = _enumDe<SexoBiologico>(
          prefs.getString(ProfilePrefsKeys.sexoBiologico),
          SexoBiologico.values);
      _eixo = _enumDe<EixoFarmacologico>(
          prefs.getString(ProfilePrefsKeys.eixoFarmacologico),
          EixoFarmacologico.values);
      final ultimaDoseIso = prefs.getString(ProfilePrefsKeys.ultimaDoseIso);
      _ultimaDose =
          ultimaDoseIso != null ? DateTime.tryParse(ultimaDoseIso) : null;

      // Medicações (catálogo público — não exige consentimento).
      _medicacoes = await auth.apiService.listarMedicacoes();

      // Perfil no backend (pode 404 se ainda não salvou). Lote 31 —
      // o backend agora é a fonte canônica também do eixo, gênero,
      // sexo e última dose; ele sobrescreve o que veio das prefs
      // quando devolve valores não-nulos, mantendo prefs como cache
      // offline.
      try {
        final json = await auth.apiService.obterPerfil();
        final perfilJson = json['perfil'] as Map<String, dynamic>?;
        if (perfilJson != null) {
          final perfil = PerfilBackend.fromJson(perfilJson);
          _declarouPrescricao = perfil.declarouPrescricao;
          _medicacaoIdSelecionada = perfil.medicationId;
          _doseCtrl.text = perfil.doseAtual ?? '';
          _pesoCtrl.text = perfil.pesoInicialKg?.toStringAsFixed(1) ?? '';
          _alturaCtrl.text = perfil.alturaCm?.toString() ?? '';
          _eixo = perfil.eixoFarmacologico ?? _eixo;
          _genero = perfil.identidadeGenero ?? _genero;
          _sexo = perfil.sexoBiologico ?? _sexo;
          _ultimaDose = perfil.ultimaDose ?? _ultimaDose;
        }
      } catch (_) {
        // Sem perfil ainda ou offline: mantém o que veio de prefs.
      }
    } catch (e) {
      _erroCarregamento = e.toString();
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  T? _enumDe<T extends Enum>(String? nome, List<T> valores) {
    if (nome == null) return null;
    for (final v in valores) {
      if (v.name == nome) return v;
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _salvando = true;
      _mensagemSalvamento = null;
    });

    final auth = context.read<AuthService>();
    try {
      // 1) Local — sempre.
      final prefs = await SharedPreferences.getInstance();
      await _salvarOuRemover(
          prefs, ProfilePrefsKeys.identidadeGenero, _genero?.name);
      await _salvarOuRemover(
          prefs, ProfilePrefsKeys.sexoBiologico, _sexo?.name);
      await _salvarOuRemover(
          prefs, ProfilePrefsKeys.eixoFarmacologico, _eixo?.name);
      await _salvarOuRemover(prefs, ProfilePrefsKeys.ultimaDoseIso,
          _ultimaDose?.toIso8601String());

      // 2) Backend — só se declarou prescrição (regra do backend).
      // Se não declarou, envia apenas peso/altura, que também servem para
      // o dashboard, com declarouPrescricao=false e sem medication_id.
      final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
      final altura = int.tryParse(_alturaCtrl.text);
      final dose = _doseCtrl.text.trim().isEmpty ? null : _doseCtrl.text.trim();

      // Lote 31 — perfil estendido também vai pro backend agora.
      // O endpoint aceita todos os campos com COALESCE, então uma
      // única chamada cobre medicação + peso/altura + eixo + gênero
      // + sexo + última dose. Sempre chamamos, mesmo sem prescrição.
      final ultimaDoseIso = _ultimaDose?.toIso8601String().split('T').first;
      await auth.apiService.salvarPerfil(
        declarouPrescricao: _declarouPrescricao,
        medicacaoId: _declarouPrescricao ? _medicacaoIdSelecionada : null,
        dosagem: _declarouPrescricao ? dose : null,
        pesoKg: peso,
        alturaCm: altura,
        eixoFarmacologico: _eixo?.name,
        identidadeGenero: _genero?.name,
        sexoBiologico: _sexo?.name,
        ultimaDoseIso: ultimaDoseIso,
      );

      if (!mounted) return;
      setState(() {
        _sucessoSalvamento = true;
        _mensagemSalvamento = 'Matriz metabólica salva.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sucessoSalvamento = false;
        _mensagemSalvamento = e.toString();
      });
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _salvarOuRemover(
      SharedPreferences prefs, String key, String? valor) async {
    if (valor == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, valor);
    }
  }

  /// Monta os filhos da seção "Terapia farmacológica" (Lote 16): eixo →
  /// medicação (filtrada) → dose → última dose → declaração. Se o eixo
  /// for "Recomposição Natural" ou não tiver categoria mapeada, esconde
  /// os campos de medicação para não confundir.
  List<Widget> _construirTerapiaFarmacologica() {
    final categorias = _eixo?.categoriasAceitas ?? const <String>[];
    final medicacoesFiltradas = categorias.isEmpty
        ? const <Map<String, dynamic>>[]
        : _medicacoes.where((m) {
            final c = m['categoria']?.toString();
            return c != null && categorias.contains(c);
          }).toList();

    // Se a medicação atualmente selecionada não está entre as filtradas
    // (ex: usuário mudou o eixo), removemos silenciosamente para evitar
    // dropdown com valor "fantasma".
    if (_medicacaoIdSelecionada != null &&
        !medicacoesFiltradas.any((m) => m['id'] == _medicacaoIdSelecionada)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _medicacaoIdSelecionada = null);
      });
    }

    final semFarma = _eixo == EixoFarmacologico.recomposicaoNatural;

    return [
      // 1) Eixo
      DropdownButtonFormField<EixoFarmacologico>(
        value: _eixo,
        decoration: const InputDecoration(
          labelText: 'Eixo farmacológico',
          prefixIcon: Icon(Icons.science_outlined),
        ),
        items: EixoFarmacologico.values
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.label, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) => setState(() => _eixo = v),
      ),

      // 2) Medicação (só aparece se o eixo envolve farmacologia)
      if (!semFarma) ...[
        const SizedBox(height: 12),
        if (categorias.isEmpty)
          _AvisoInline(
            texto:
                'Sem medicações aprovadas no catálogo Anvisa para esse eixo '
                'nesta versão do app. Se surgir uma opção, adicionaremos.',
          )
        else
          DropdownButtonFormField<int?>(
            value: _medicacaoIdSelecionada,
            decoration: const InputDecoration(
              labelText: 'Medicação',
              prefixIcon: Icon(Icons.medication_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Nenhuma'),
              ),
              ...medicacoesFiltradas.map((m) {
                final id = m['id'] as int?;
                final nome = (m['nome_comercial'] ?? m['nome']) as String?;
                final fab = m['fabricante']?.toString();
                final rotulo = (nome != null && fab != null && fab.isNotEmpty)
                    ? '$nome · $fab'
                    : (nome ?? '—');
                return DropdownMenuItem<int?>(
                  value: id,
                  child: Text(rotulo, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (v) => setState(() => _medicacaoIdSelecionada = v),
          ),

        // 3) Dose
        const SizedBox(height: 12),
        TextFormField(
          controller: _doseCtrl,
          decoration: const InputDecoration(
            labelText: 'Dose atual',
            hintText: 'ex.: 10mg semanal',
            prefixIcon: Icon(Icons.medication_liquid_outlined),
          ),
        ),

        // 4) Data da última dose
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Data da última dose',
            prefixIcon: Icon(Icons.event_outlined),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _ultimaDose != null
                      ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_ultimaDose!)
                      : 'Não informada',
                ),
              ),
              if (_ultimaDose != null)
                IconButton(
                  tooltip: 'Remover data',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _ultimaDose = null),
                ),
              TextButton.icon(
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Escolher'),
                onPressed: _pickUltimaDose,
              ),
            ],
          ),
        ),

        // 5) Declaração de prescrição
        const SizedBox(height: 4),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _declarouPrescricao,
          onChanged: (v) => setState(() => _declarouPrescricao = v ?? false),
          title: const Text(
            'Declaro que possuo prescrição médica válida para esta medicação '
            '(exigido para salvar dados farmacológicos — Termos §3.1).',
            style: TextStyle(fontSize: 12.5, height: 1.35),
          ),
          activeColor: AppColors.verdeConfirma,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ] else ...[
        const SizedBox(height: 8),
        _AvisoInline(
          texto:
              'Recomposição Natural — o app não pede dados de medicação; '
              'o foco fica em peso, alimentação e atividade.',
        ),
      ],
    ];
  }

  Future<void> _pickUltimaDose() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _ultimaDose ?? agora,
      firstDate: DateTime(agora.year - 5),
      lastDate: agora,
      locale: const Locale('pt', 'BR'),
      helpText: 'Data da última dose',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (escolhida != null && mounted) {
      setState(() => _ultimaDose = escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erroCarregamento != null) {
      return _ErroCarga(
          mensagem: _erroCarregamento!, onTentar: _carregarTudo);
    }

    return SingleChildScrollView(
      // padding-bottom 96 dá espaço para a FloatingNavBar (Lote 14) que
      // fica sobre o conteúdo via extendBody — o botão "Gerar Matriz
      // Metabólica" precisa desse espaço para não ficar coberto.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            const SizedBox(height: 16),

            _Secao(
              titulo: 'Identidade',
              subtitulo:
                  'Usado para orientações mais adequadas ao seu perfil. '
                  'Guardado só no seu dispositivo neste momento.',
              filhos: [
                _DropdownGenero(
                  valor: _genero,
                  onChanged: (v) => setState(() => _genero = v),
                ),
                const SizedBox(height: 12),
                _DropdownSexo(
                  valor: _sexo,
                  onChanged: (v) => setState(() => _sexo = v),
                ),
              ],
            ),

            _Secao(
              titulo: 'Composição corporal',
              subtitulo: 'Peso e altura são cifrados no servidor.',
              filhos: [
                TextFormField(
                  controller: _pesoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'ex.: 78.5',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null) return 'Número inválido';
                    if (n < 20 || n > 400) return 'Fora de faixa (20–400 kg)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alturaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Altura (cm)',
                    hintText: 'ex.: 172',
                    prefixIcon: Icon(Icons.height),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null) return 'Número inválido';
                    if (n < 100 || n > 250) return 'Fora de faixa (100–250 cm)';
                    return null;
                  },
                ),
              ],
            ),

            _Secao(
              titulo: 'Terapia farmacológica',
              subtitulo:
                  'O eixo define sua matriz metabólica; a medicação é '
                  'filtrada automaticamente pela compatibilidade com o eixo.',
              filhos: _construirTerapiaFarmacologica(),
            ),

            if (_mensagemSalvamento != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_sucessoSalvamento
                          ? AppColors.verdeConfirma
                          : AppColors.vermelhoAlerta)
                      .withValues(alpha: 0.1),
                  border: Border.all(
                    color: _sucessoSalvamento
                        ? AppColors.verdeConfirma
                        : AppColors.vermelhoAlerta,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sucessoSalvamento
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: _sucessoSalvamento
                          ? AppColors.verdeConfirma
                          : AppColors.vermelhoAlerta,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_mensagemSalvamento!,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text(
                  'Gerar Matriz Metabólica',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
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
            // Lote 32.5 — Segurança do app (PIN + biometria).
            const _CardAppLock(),
            const SizedBox(height: 16),
            // Lote 32.7 — Notificações contextuais.
            const _CardNotificacoes(),
            const SizedBox(height: 16),
            // Lote 32.6 — Meus dados (LGPD).
            const _CardMeusDados(),
            const SizedBox(height: 16),
            const _CardPremium(),
            const SizedBox(height: 16),
            const _CardAparencia(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Lote 24 — Toggle discreto de tema (Automático / Claro / Escuro).
class _CardAparencia extends StatelessWidget {
  const _CardAparencia();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (ctx, controller, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(RecorpoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.palette_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Aparência',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto, size: 16),
                      label: Text('Auto', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                      label: Text('Claro', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                      label: Text('Escuro', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {controller.mode},
                  onSelectionChanged: (s) => controller.setMode(s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lote 32.5 — Cartão de segurança do app (PIN + biometria).
///
/// Estado ligado: mostra timeout selecionado + botão desativar (pede PIN
/// atual). Estado desligado: CTA para abrir setup.
class _CardAppLock extends StatelessWidget {
  const _CardAppLock();

  static String _rotuloTimeout(int seg) {
    switch (seg) {
      case 0:
        return 'bloqueio imediato';
      case 60:
        return 'após 1 minuto';
      case 300:
        return 'após 5 minutos';
      case 900:
        return 'após 15 minutos';
      default:
        return 'após ${seg}s';
    }
  }

  Future<void> _desativar(BuildContext context) async {
    final lock = context.read<AppLockService>();
    final pinCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Desativar bloqueio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite seu PIN atual para desativar.'),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await lock.desativar(pinCtrl.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bloqueio desativado.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorreto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockService>();
    final scheme = Theme.of(context).colorScheme;
    final ativado = lock.configurado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: RecorpoGradients.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bloqueio do app',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      ativado
                          ? 'Ativo · ${_rotuloTimeout(lock.timeoutSeg)}${lock.biometriaHabilitada ? ' · biometria' : ''}'
                          : 'Proteja dados sensíveis com PIN e biometria.',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ativado
                    ? OutlinedButton(
                        onPressed: () => _desativar(context),
                        child: const Text('Desativar'),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AppLockSetupScreen()),
                        ),
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: const Text('Ativar bloqueio'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lote 32.7 — Cartão pra controlar as notificações contextuais
/// (hidratação inteligente e check-in mensal). Ambas opt-in por
/// padrão; desligar cancela imediatamente pelo NotificationService.
class _CardNotificacoes extends StatefulWidget {
  const _CardNotificacoes();

  @override
  State<_CardNotificacoes> createState() => _CardNotificacoesState();
}

class _CardNotificacoesState extends State<_CardNotificacoes> {
  bool _hidratacao = true;
  bool _mensal = true;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hidratacao =
          prefs.getBool(ProfilePrefsKeys.notifHidratacao) ?? true;
      _mensal =
          prefs.getBool(ProfilePrefsKeys.notifCheckInMensal) ?? true;
      _carregando = false;
    });
  }

  Future<void> _mudarHidratacao(bool v) async {
    setState(() => _hidratacao = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ProfilePrefsKeys.notifHidratacao, v);
    if (!v) await NotificationService().cancelarHidratacaoMeioDia();
  }

  Future<void> _mudarMensal(bool v) async {
    // Captura o service antes de qualquer await pra evitar uso de
    // BuildContext em async gap.
    final auth = context.read<AuthService>();
    setState(() => _mensal = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ProfilePrefsKeys.notifCheckInMensal, v);
    if (v) {
      await NotificationService().agendarCheckInMensal(
        primeiroNome: (auth.nome ?? '').trim().split(' ').first,
      );
    } else {
      await NotificationService().cancelarCheckInMensal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: RecorpoGradients.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificações contextuais',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      'Só quando fizer sentido para você.',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hidratacao,
              onChanged: _mudarHidratacao,
              title: const Text('Lembrete de hidratação'),
              subtitle: const Text(
                  '13h de hoje, apenas se você estiver abaixo da meta.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _mensal,
              onChanged: _mudarMensal,
              title: const Text('Check-in mensal'),
              subtitle: const Text(
                  'Dia 1 às 10h, com resumo para levar ao médico.'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lote 32.6 — Cartão de acesso à tela "Meus dados" (LGPD).
class _CardMeusDados extends StatelessWidget {
  const _CardMeusDados();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MeusDadosScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RecorpoGradients.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_shared_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meus dados',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    'Exportar, ver acessos, excluir conta (LGPD).',
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

/// Lote 23 — Cartão que abre a paywall (ou avisa que é Premium).
class _CardPremium extends StatelessWidget {
  const _CardPremium();

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (ctx, premium, _) {
        final ehPro = premium.isPremium;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ehPro
                    ? const [AppColors.verdeConfirma, Color(0xFF2F855A)]
                    : const [AppColors.azulClinico, Color(0xFF4A90D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                    ehPro
                        ? Icons.workspace_premium
                        : Icons.rocket_launch_outlined,
                    color: Colors.white,
                    size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ehPro ? 'Você é Premium 🎉' : 'Recorpo Premium',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ehPro
                            ? 'Todas as features desbloqueadas'
                            : 'A partir de R\$ 12,49/mês (anual)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.azulClinico,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.nome ?? 'Usuário',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(auth.email ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> filhos;
  const _Secao({required this.titulo, this.subtitulo, required this.filhos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              if (subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(subtitulo!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 12),
              ...filhos,
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownGenero extends StatelessWidget {
  final IdentidadeGenero? valor;
  final ValueChanged<IdentidadeGenero?> onChanged;
  const _DropdownGenero({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<IdentidadeGenero>(
      value: valor,
      decoration: const InputDecoration(
        labelText: 'Identidade de gênero',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: IdentidadeGenero.values
          .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DropdownSexo extends StatelessWidget {
  final SexoBiologico? valor;
  final ValueChanged<SexoBiologico?> onChanged;
  const _DropdownSexo({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SexoBiologico>(
      value: valor,
      decoration: const InputDecoration(
        labelText: 'Sexo biológico',
        prefixIcon: Icon(Icons.biotech_outlined),
      ),
      items: SexoBiologico.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Caixa de aviso inline usada dentro da seção "Terapia farmacológica"
/// para explicar situações onde não há medicação disponível (miostatina,
/// natural, triplo agonista sem droga aprovada).
class _AvisoInline extends StatelessWidget {
  final String texto;
  const _AvisoInline({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroCarga extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentar;
  const _ErroCarga({required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.vermelhoAlerta),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onTentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
