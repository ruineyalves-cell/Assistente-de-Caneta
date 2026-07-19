import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_lock_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Lote 32.5 — Tela de desbloqueio.
///
/// Pode ser exibida no boot (se PIN configurado) ou depois do
/// auto-lock por inatividade. Tenta biometria automaticamente se
/// habilitada; PIN fica como fallback com teclado numérico próprio.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  bool _tentandoBiometria = false;
  String? _erro;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tentarBiometriaAutomatica();
    // Refresh de 1s pra atualizar o contador de bloqueio temporário.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _tentarBiometriaAutomatica() async {
    final lock = context.read<AppLockService>();
    if (!lock.biometriaHabilitada) return;
    setState(() => _tentandoBiometria = true);
    final ok = await lock.tentarBiometria();
    if (!mounted) return;
    setState(() {
      _tentandoBiometria = false;
      if (!ok) _erro = null; // usuário só cancelou; sem mensagem
    });
  }

  Future<void> _adicionar(int d) async {
    if (_pin.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin + d.toString();
      _erro = null;
    });
    if (_pin.length >= 4) {
      // Não validamos automaticamente aos 4 dígitos porque o PIN pode
      // ter 5 ou 6. A validação acontece no botão OK ou aos 6 dígitos.
      if (_pin.length == 6) {
        await _tentarPin();
      }
    }
  }

  Future<void> _apagar() async {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _erro = null;
    });
  }

  Future<void> _tentarPin() async {
    final lock = context.read<AppLockService>();
    if (_pin.length < 4) {
      setState(() => _erro = 'Digite pelo menos 4 dígitos.');
      return;
    }
    final ok = await lock.verificarPin(_pin);
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() {
        _erro = 'PIN incorreto.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lock = context.watch<AppLockService>();
    final bloqAte = lock.bloqueadoAte;
    final tempBloqueado =
        bloqAte != null && bloqAte.isAfter(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: RecorpoGradients.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: RecorpoColors.primary.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.brandName,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                _tentandoBiometria
                    ? 'Autenticando…'
                    : 'Digite seu PIN para desbloquear',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 32),
              _Dots(preenchidos: _pin.length),
              const SizedBox(height: 16),
              if (tempBloqueado)
                _AvisoBloqueio(ate: bloqAte)
              else if (_erro != null)
                Center(
                  child: Text(_erro!,
                      style: TextStyle(
                          color: RecorpoColors.alertaClinico,
                          fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              _Teclado(
                onDigito: tempBloqueado ? null : _adicionar,
                onApagar: tempBloqueado ? null : _apagar,
                onBiometria: lock.biometriaHabilitada && !tempBloqueado
                    ? _tentarBiometriaAutomatica
                    : null,
                onOk: _pin.length >= 4 && !tempBloqueado ? _tentarPin : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int preenchidos;
  const _Dots({required this.preenchidos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final cheio = i < preenchidos;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cheio
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }
}

class _AvisoBloqueio extends StatelessWidget {
  final DateTime ate;
  const _AvisoBloqueio({required this.ate});

  @override
  Widget build(BuildContext context) {
    final segundos = ate.difference(DateTime.now()).inSeconds;
    return Center(
      child: Text(
        'Muitas tentativas erradas. Tente novamente em ${segundos > 0 ? segundos : 0}s.',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: RecorpoColors.alertaClinico,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Teclado extends StatelessWidget {
  final Future<void> Function(int)? onDigito;
  final Future<void> Function()? onApagar;
  final Future<void> Function()? onBiometria;
  final Future<void> Function()? onOk;

  const _Teclado({
    required this.onDigito,
    required this.onApagar,
    required this.onBiometria,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    Widget num(int n) => _BotaoTeclado(
          label: '$n',
          onTap: onDigito == null ? null : () => onDigito!(n),
        );

    Widget acao({
      required Widget child,
      required Future<void> Function()? onTap,
    }) =>
        _BotaoTeclado(child: child, onTap: onTap);

    return Column(
      children: [
        Row(children: [
          Expanded(child: num(1)),
          Expanded(child: num(2)),
          Expanded(child: num(3)),
        ]),
        Row(children: [
          Expanded(child: num(4)),
          Expanded(child: num(5)),
          Expanded(child: num(6)),
        ]),
        Row(children: [
          Expanded(child: num(7)),
          Expanded(child: num(8)),
          Expanded(child: num(9)),
        ]),
        Row(children: [
          Expanded(
            child: acao(
              child: onBiometria == null
                  ? const SizedBox()
                  : const Icon(Icons.fingerprint, size: 32),
              onTap: onBiometria,
            ),
          ),
          Expanded(child: num(0)),
          Expanded(
            child: onOk != null
                ? acao(
                    child:
                        const Icon(Icons.check_circle_outline, size: 32),
                    onTap: onOk,
                  )
                : acao(
                    child: const Icon(Icons.backspace_outlined, size: 26),
                    onTap: onApagar,
                  ),
          ),
        ]),
      ],
    );
  }
}

class _BotaoTeclado extends StatelessWidget {
  final String? label;
  final Widget? child;
  final Future<void> Function()? onTap;

  const _BotaoTeclado({this.label, this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null
                  ? scheme.onSurface.withValues(alpha: 0.04)
                  : scheme.onSurface.withValues(alpha: 0.06),
            ),
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: onTap == null
                            ? scheme.onSurface.withValues(alpha: 0.25)
                            : scheme.onSurface),
                  )
                : (child ?? const SizedBox()),
          ),
        ),
      ),
    );
  }
}
