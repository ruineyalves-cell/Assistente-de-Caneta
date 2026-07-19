import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Lote 29 — Onboarding em 3 telas após o primeiro login.
///
/// Fluxo: Boas-vindas → Eixo/medicação → Peso atual + meta.
/// Ao concluir (ou pular), grava [AppConstants.keyOnboardingCompleto] em
/// `SharedPreferences` e chama [onConcluir] para o `MyApp` remontar
/// levando o usuário ao `DashboardPage`.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onConcluir;

  const OnboardingScreen({super.key, required this.onConcluir});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _passo = 0;

  // Passo 2 — eixo + medicação
  EixoFarmacologico? _eixo;
  int? _medicacaoId;
  List<Map<String, dynamic>> _medicacoesDisponiveis = const [];
  bool _carregandoMedicacoes = false;

  // Passo 3 — peso atual + meta
  final _pesoAtualCtrl = TextEditingController();
  final _metaPesoCtrl = TextEditingController();

  bool _salvando = false;
  String? _erroFinal;

  @override
  void dispose() {
    _pageController.dispose();
    _pesoAtualCtrl.dispose();
    _metaPesoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarMedicacoesDoEixo(EixoFarmacologico eixo) async {
    if (!eixo.envolveMedicacao) {
      setState(() {
        _medicacoesDisponiveis = const [];
        _medicacaoId = null;
      });
      return;
    }
    setState(() => _carregandoMedicacoes = true);
    try {
      final auth = context.read<AuthService>();
      final todas = await auth.apiService.listarMedicacoes();
      final categorias = eixo.categoriasAceitas.toSet();
      final filtradas = todas.where((m) {
        final cat = (m['categoria'] as String?) ?? '';
        return categorias.isEmpty || categorias.contains(cat);
      }).toList();
      if (!mounted) return;
      setState(() {
        _medicacoesDisponiveis = filtradas;
        _carregandoMedicacoes = false;
        // Se a medicação previamente escolhida não está mais na lista,
        // limpa para o usuário reescolher.
        if (_medicacaoId != null &&
            !filtradas.any((m) => m['id'] == _medicacaoId)) {
          _medicacaoId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _medicacoesDisponiveis = const [];
        _carregandoMedicacoes = false;
      });
    }
  }

  bool get _podeAvancar {
    switch (_passo) {
      case 0:
        return true;
      case 1:
        // Precisa escolher um eixo. Medicação é opcional (pode escolher
        // depois no perfil), inclusive porque o catálogo pode não ter
        // itens compatíveis (ex.: miostatina).
        return _eixo != null;
      case 2:
        // Peso atual é obrigatório; meta é opcional (usuário pode não
        // ter alvo definido ainda).
        final peso =
            double.tryParse(_pesoAtualCtrl.text.trim().replaceAll(',', '.'));
        return peso != null && peso > 20 && peso < 400;
      default:
        return false;
    }
  }

  Future<void> _proximo() async {
    if (_passo < 2) {
      setState(() => _passo++);
      await _pageController.animateToPage(
        _passo,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      if (_passo == 1 && _eixo != null && _medicacoesDisponiveis.isEmpty) {
        // Se o usuário voltou pro passo 1 e trocou de eixo, recarrega.
        await _carregarMedicacoesDoEixo(_eixo!);
      }
      return;
    }
    await _concluir();
  }

  void _voltar() {
    if (_passo == 0) return;
    setState(() => _passo--);
    _pageController.animateToPage(
      _passo,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pular() async {
    // Pular grava só a flag: usuário pode configurar tudo depois no perfil.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleto, true);
    if (!mounted) return;
    widget.onConcluir();
  }

  Future<void> _concluir() async {
    setState(() {
      _salvando = true;
      _erroFinal = null;
    });

    final peso =
        double.tryParse(_pesoAtualCtrl.text.trim().replaceAll(',', '.'));
    final meta =
        double.tryParse(_metaPesoCtrl.text.trim().replaceAll(',', '.'));
    // Captura o service antes do primeiro await para evitar uso de
    // BuildContext em async gap.
    final auth = context.read<AuthService>();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Lote 31 — Agora enviamos eixo + meta de peso via backend
      // (patient_profiles.eixo_farmacologico / meta_peso_kg_enc), pra
      // sobreviver a troca de aparelho. Mantemos também as prefs locais
      // como cache offline e retrocompatibilidade com telas que ainda
      // leem de lá antes do próximo GET de perfil.
      if (_eixo != null) {
        await prefs.setString(
            ProfilePrefsKeys.eixoFarmacologico, _eixo!.name);
      }
      final metaValida = meta != null && meta > 20 && meta < 400;
      if (metaValida) {
        await prefs.setDouble(ProfilePrefsKeys.metaPesoKg, meta);
      }

      // Salvar no backend: peso + medicação + perfil estendido.
      final envolveMed = _eixo?.envolveMedicacao ?? false;
      await auth.apiService.salvarPerfil(
        declarouPrescricao: envolveMed && _medicacaoId != null,
        medicacaoId: _medicacaoId,
        pesoKg: peso,
        eixoFarmacologico: _eixo?.name,
        metaPesoKg: metaValida ? meta : null,
      );

      await prefs.setBool(AppConstants.keyOnboardingCompleto, true);
      if (!mounted) return;
      widget.onConcluir();
    } catch (e) {
      // Não bloquear o usuário se o backend falhou: peso é salvo no
      // próximo log e a flag ainda é marcada para não repetir a tela.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyOnboardingCompleto, true);
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erroFinal =
            'Configuração salva localmente. Alguns dados sincronizam quando o servidor voltar.';
      });
      // Mesmo com erro, seguimos para o Dashboard após 2s de aviso.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) widget.onConcluir();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ehDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header — indicador de progresso e ação de pular.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RecorpoSpacing.lg,
                RecorpoSpacing.lg,
                RecorpoSpacing.lg,
                RecorpoSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(3, (i) {
                        final ativo = i <= _passo;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                                right: i == 2 ? 0 : RecorpoSpacing.xs),
                            decoration: BoxDecoration(
                              color: ativo
                                  ? scheme.primary
                                  : scheme.onSurface.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: RecorpoSpacing.md),
                  TextButton(
                    onPressed: _salvando ? null : _pular,
                    child: const Text('Pular'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PassoBemVindo(ehDark: ehDark),
                  _PassoMedicacao(
                    ehDark: ehDark,
                    eixo: _eixo,
                    medicacaoId: _medicacaoId,
                    carregando: _carregandoMedicacoes,
                    medicacoes: _medicacoesDisponiveis,
                    onEixoMudou: (novo) {
                      setState(() {
                        _eixo = novo;
                        _medicacaoId = null;
                      });
                      _carregarMedicacoesDoEixo(novo);
                    },
                    onMedicacaoMudou: (id) {
                      setState(() => _medicacaoId = id);
                    },
                  ),
                  _PassoMetaPeso(
                    ehDark: ehDark,
                    pesoAtualCtrl: _pesoAtualCtrl,
                    metaPesoCtrl: _metaPesoCtrl,
                    onMudou: () => setState(() {}),
                  ),
                ],
              ),
            ),

            if (_erroFinal != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: RecorpoSpacing.lg,
                    vertical: RecorpoSpacing.sm),
                child: Text(
                  _erroFinal!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),

            // Footer — voltar + próximo/concluir.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RecorpoSpacing.lg,
                RecorpoSpacing.sm,
                RecorpoSpacing.lg,
                RecorpoSpacing.lg,
              ),
              child: Row(
                children: [
                  if (_passo > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _salvando ? null : _voltar,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                RecorpoSpacing.radiusMd),
                          ),
                        ),
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (_passo > 0) const SizedBox(width: RecorpoSpacing.md),
                  Expanded(
                    flex: _passo == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed:
                          (!_podeAvancar || _salvando) ? null : _proximo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(RecorpoSpacing.radiusMd),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _passo < 2 ? 'Continuar' : 'Concluir',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────
// PASSO 1 — Boas-vindas
// ─────────────────────────────────────────────────────────────────────────
class _PassoBemVindo extends StatelessWidget {
  final bool ehDark;
  const _PassoBemVindo({required this.ehDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RecorpoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Container(
            width: 108,
            height: 108,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RecorpoGradients.primary,
              boxShadow: [
                BoxShadow(
                  color: RecorpoColors.primary.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(Icons.vaccines, size: 52, color: Colors.white),
          ),
          const SizedBox(height: RecorpoSpacing.xl),
          Text(
            'Boas-vindas ao ${AppConstants.brandName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: RecorpoSpacing.md),
          Text(
            'Vamos configurar duas coisas rápidas para personalizar seu '
            'acompanhamento. Leva menos de 1 minuto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: RecorpoSpacing.xxl),
          const _ItemCheck(
            eixo: EixoRecorpo.primary,
            titulo: 'Sua medicação',
            subtitulo: 'Para calibrar orientações e alertas.',
          ),
          const SizedBox(height: RecorpoSpacing.md),
          const _ItemCheck(
            eixo: EixoRecorpo.peso,
            titulo: 'Peso atual e meta',
            subtitulo: 'Para acompanhar sua evolução.',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ItemCheck extends StatelessWidget {
  final EixoRecorpo eixo;
  final String titulo;
  final String subtitulo;
  const _ItemCheck({
    required this.eixo,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: eixo.gradiente,
            borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
          ),
          child: Icon(eixo.icone, color: Colors.white, size: 22),
        ),
        const SizedBox(width: RecorpoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitulo,
                  style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.65))),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PASSO 2 — Eixo farmacológico + medicação
// ─────────────────────────────────────────────────────────────────────────
class _PassoMedicacao extends StatelessWidget {
  final bool ehDark;
  final EixoFarmacologico? eixo;
  final int? medicacaoId;
  final bool carregando;
  final List<Map<String, dynamic>> medicacoes;
  final ValueChanged<EixoFarmacologico> onEixoMudou;
  final ValueChanged<int?> onMedicacaoMudou;

  const _PassoMedicacao({
    required this.ehDark,
    required this.eixo,
    required this.medicacaoId,
    required this.carregando,
    required this.medicacoes,
    required this.onEixoMudou,
    required this.onMedicacaoMudou,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: RecorpoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: RecorpoSpacing.md),
          Text('Sua matriz metabólica',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
          const SizedBox(height: RecorpoSpacing.sm),
          Text(
            'Escolha o eixo que corresponde ao seu tratamento — as '
            'orientações do dashboard usam essa informação.',
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: RecorpoSpacing.lg),

          ...EixoFarmacologico.values.map((e) {
            final selecionado = eixo == e;
            return Padding(
              padding: const EdgeInsets.only(bottom: RecorpoSpacing.sm),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusSm),
                onTap: () => onEixoMudou(e),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: RecorpoSpacing.md,
                      vertical: RecorpoSpacing.md),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? scheme.primary.withValues(alpha: 0.12)
                        : scheme.surface,
                    borderRadius:
                        BorderRadius.circular(RecorpoSpacing.radiusSm),
                    border: Border.all(
                      color: selecionado
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.12),
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selecionado
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selecionado
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: RecorpoSpacing.md),
                      Expanded(
                        child: Text(
                          e.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selecionado
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: RecorpoSpacing.lg),
          if (eixo != null && eixo!.envolveMedicacao) ...[
            Text('Medicação (opcional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.75))),
            const SizedBox(height: RecorpoSpacing.sm),
            if (carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (medicacoes.isEmpty)
              Text(
                'Sem medicações desta categoria no catálogo por enquanto — '
                'você pode configurar depois no Perfil.',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      BorderRadius.circular(RecorpoSpacing.radiusSm),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: medicacaoId,
                    hint: const Text('Selecione a medicação'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('— não informar por agora —'),
                      ),
                      ...medicacoes.map((m) {
                        final id = m['id'] as int;
                        final nome = (m['nome'] as String?) ?? '—';
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(nome, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: onMedicacaoMudou,
                  ),
                ),
              ),
          ],
          const SizedBox(height: RecorpoSpacing.lg),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PASSO 3 — Peso atual + meta
// ─────────────────────────────────────────────────────────────────────────
class _PassoMetaPeso extends StatelessWidget {
  final bool ehDark;
  final TextEditingController pesoAtualCtrl;
  final TextEditingController metaPesoCtrl;
  final VoidCallback onMudou;

  const _PassoMetaPeso({
    required this.ehDark,
    required this.pesoAtualCtrl,
    required this.metaPesoCtrl,
    required this.onMudou,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: RecorpoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: RecorpoSpacing.md),
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: RecorpoGradients.peso,
              borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
            ),
            child: const Icon(Icons.monitor_weight_outlined,
                size: 34, color: Colors.white),
          ),
          const SizedBox(height: RecorpoSpacing.lg),
          Text('Sua meta de peso',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
          const SizedBox(height: RecorpoSpacing.sm),
          Text(
            'Serve como referência para o gráfico de evolução. Você pode '
            'alterar a qualquer momento no perfil.',
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: RecorpoSpacing.xl),

          _CampoPeso(
            controller: pesoAtualCtrl,
            label: 'Peso atual (kg)',
            hint: 'Ex.: 98.5',
            icone: Icons.scale_outlined,
            onChanged: (_) => onMudou(),
          ),
          const SizedBox(height: RecorpoSpacing.md),
          _CampoPeso(
            controller: metaPesoCtrl,
            label: 'Meta de peso (kg) — opcional',
            hint: 'Ex.: 82.0',
            icone: Icons.flag_outlined,
            onChanged: (_) => onMudou(),
          ),
          const SizedBox(height: RecorpoSpacing.lg),
          Container(
            padding: const EdgeInsets.all(RecorpoSpacing.md),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: scheme.primary),
                const SizedBox(width: RecorpoSpacing.sm),
                Expanded(
                  child: Text(
                    'Perda saudável fica entre 0,5 e 1 kg por semana '
                    '(ABESO/OMS). Nada de metas agressivas — o app '
                    'acompanha seu ritmo, não força.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RecorpoSpacing.lg),
        ],
      ),
    );
  }
}

class _CampoPeso extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icone;
  final ValueChanged<String> onChanged;

  const _CampoPeso({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ehDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final fill = ehDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white;
    final borderColor = ehDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: scheme.onSurface, fontSize: 15),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.75)),
        hintText: hint,
        hintStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.4)),
        prefixIcon: Icon(icone,
            color: scheme.onSurface.withValues(alpha: 0.6)),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
