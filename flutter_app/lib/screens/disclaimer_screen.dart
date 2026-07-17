import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Tela de aceite obrigatório dos Termos + Política de Privacidade, exibida
/// na primeira execução do app (gate anterior ao login). O botão principal
/// "Compreendo e Aceito" só habilita depois que o usuário rola o texto até
/// o fim. Após o aceite, persiste [AppConstants.keyDisclaimerAceito] no
/// shared_preferences para não perguntar de novo.
class DisclaimerScreen extends StatefulWidget {
  /// Chamado depois que o aceite foi persistido com sucesso.
  final VoidCallback onAceito;

  const DisclaimerScreen({super.key, required this.onAceito});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  final _scroll = ScrollController();
  bool _leuTudo = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Se o conteúdo couber sem rolar (tablet grande), libera após o 1º frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients &&
          _scroll.position.maxScrollExtent <= 0 &&
          !_leuTudo) {
        setState(() => _leuTudo = true);
      }
    });
  }

  void _onScroll() {
    if (!_leuTudo &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 24) {
      setState(() => _leuTudo = true);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _aceitar() async {
    setState(() => _salvando = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyDisclaimerAceito, true);
    if (!mounted) return;
    widget.onAceito();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.azulClinico,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.privacy_tip,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Termos de Uso e Privacidade',
                                style: theme.textTheme.titleLarge),
                            Text(
                              _leuTudo
                                  ? 'Você chegou ao fim — libere o aceite abaixo.'
                                  : 'Role até o final para habilitar o aceite.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Scrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scroll,
                          child: const Text(
                            AppConstants.termosLegaisTexto,
                            style: TextStyle(fontSize: 13, height: 1.55),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_leuTudo && !_salvando) ? _aceitar : null,
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
                          : const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Compreendo e Aceito',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClinico,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.azulClinico.withValues(alpha: 0.35),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
