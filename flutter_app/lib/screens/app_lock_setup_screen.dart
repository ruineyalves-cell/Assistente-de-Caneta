import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_lock_service.dart';
import '../utils/theme.dart';

/// Lote 32.5 — Setup do bloqueio.
///
/// Fluxo:
///  1. Digite o PIN (4-6 dígitos).
///  2. Confirme o PIN.
///  3. Ative biometria (se disponível).
///  4. Escolha o tempo de auto-lock (0 imediato / 1 min / 5 min / 15 min).
class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  int _passo = 0;
  String _pin1 = '';
  String _pin2 = '';
  bool _biometriaSuportada = false;
  bool _ativarBiometria = false;
  int _timeoutSeg = 300;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
    final lock = context.read<AppLockService>();
    final ok = await lock.biometriaDisponivel();
    if (!mounted) return;
    setState(() {
      _biometriaSuportada = ok;
      _ativarBiometria = ok; // default: ligado se suporta
    });
  }

  Future<void> _concluir() async {
    setState(() => _erro = null);
    if (_pin1 != _pin2) {
      setState(() => _erro = 'Os PINs não coincidem.');
      return;
    }
    final lock = context.read<AppLockService>();
    try {
      await lock.definirPin(_pin1);
      if (_biometriaSuportada && _ativarBiometria) {
        try {
          await lock.definirBiometria(true);
        } catch (_) {
          // biometria falhou de configurar — sem bloqueio da UX
        }
      }
      await lock.definirTimeout(_timeoutSeg);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueio ativado.')),
      );
    } catch (e) {
      setState(() => _erro = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ativar bloqueio')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RecorpoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IndicadorProgresso(passo: _passo, total: _passoTotal),
              const SizedBox(height: RecorpoSpacing.xl),
              Expanded(child: _construirPasso()),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_erro!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              _acoes(),
            ],
          ),
        ),
      ),
    );
  }

  int get _passoTotal => _biometriaSuportada ? 4 : 3;

  Widget _construirPasso() {
    switch (_passo) {
      case 0:
        return _PassoPin(
          titulo: 'Crie um PIN de 4 a 6 dígitos',
          subtitulo: 'Você vai usar esse PIN para desbloquear o app.',
          valor: _pin1,
          onMudou: (v) => setState(() => _pin1 = v),
        );
      case 1:
        return _PassoPin(
          titulo: 'Confirme o PIN',
          subtitulo: 'Digite exatamente o mesmo PIN.',
          valor: _pin2,
          onMudou: (v) => setState(() => _pin2 = v),
        );
      case 2:
        if (_biometriaSuportada) {
          return _PassoBiometria(
            ativar: _ativarBiometria,
            onMudar: (v) => setState(() => _ativarBiometria = v),
          );
        }
        return _PassoTimeout(
          selecionado: _timeoutSeg,
          onMudar: (v) => setState(() => _timeoutSeg = v),
        );
      case 3:
        return _PassoTimeout(
          selecionado: _timeoutSeg,
          onMudar: (v) => setState(() => _timeoutSeg = v),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _acoes() {
    final ehUltimo = _passo == _passoTotal - 1;
    final podeAvancar = _podeAvancar();
    return Row(
      children: [
        if (_passo > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _passo--),
              child: const Text('Voltar'),
            ),
          ),
        if (_passo > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: podeAvancar
                ? () async {
                    if (ehUltimo) {
                      await _concluir();
                    } else {
                      setState(() => _passo++);
                    }
                  }
                : null,
            child: Text(ehUltimo ? 'Ativar' : 'Continuar'),
          ),
        ),
      ],
    );
  }

  bool _podeAvancar() {
    switch (_passo) {
      case 0:
        return _pin1.length >= 4 && _pin1.length <= 6;
      case 1:
        return _pin2.length == _pin1.length;
      case 2:
      case 3:
        return true;
      default:
        return false;
    }
  }
}

class _IndicadorProgresso extends StatelessWidget {
  final int passo;
  final int total;
  const _IndicadorProgresso({required this.passo, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final ativo = i <= passo;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: ativo
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _PassoPin extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String valor;
  final ValueChanged<String> onMudou;
  const _PassoPin({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onMudou,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(subtitulo,
            style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: RecorpoSpacing.xl),
        TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: 12,
          ),
          onChanged: onMudou,
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            hintStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.2),
                letterSpacing: 12),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }
}

class _PassoBiometria extends StatelessWidget {
  final bool ativar;
  final ValueChanged<bool> onMudar;
  const _PassoBiometria({required this.ativar, required this.onMudar});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Usar biometria?',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(
          'Impressão digital ou reconhecimento facial evita digitar o PIN toda vez. O PIN continua sendo o fallback.',
          style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: RecorpoSpacing.xl),
        SwitchListTile(
          value: ativar,
          onChanged: onMudar,
          contentPadding: EdgeInsets.zero,
          title: const Text('Ativar biometria'),
          subtitle: const Text('Recomendado se seu aparelho já configurou.'),
        ),
      ],
    );
  }
}

class _PassoTimeout extends StatelessWidget {
  final int selecionado;
  final ValueChanged<int> onMudar;
  const _PassoTimeout({required this.selecionado, required this.onMudar});

  static String _rotulo(int seg) {
    switch (seg) {
      case 0:
        return 'Imediato';
      case 60:
        return '1 minuto';
      case 300:
        return '5 minutos';
      case 900:
        return '15 minutos';
      default:
        return '$seg s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bloquear após inatividade',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(
          'Se o app ficar mais tempo que isso em segundo plano, exigimos desbloqueio de novo.',
          style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: RecorpoSpacing.xl),
        ...AppLockService.timeoutsDisponiveisSeg.map((s) {
          final sel = selecionado == s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onMudar(s),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? scheme.primary.withValues(alpha: 0.12)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.12),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: sel
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Text(_rotulo(s),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
