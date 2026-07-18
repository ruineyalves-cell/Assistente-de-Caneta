import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../utils/constants.dart';
import '../screens/paywall_screen.dart';

/// Wrapper de UI para features Pro. Se o usuário for Premium, mostra o
/// [child]; senão, mostra uma versão com selo "Pro" e abre a Paywall ao
/// tocar.
///
/// Uso:
/// ```dart
/// FeatureGate(
///   feature: Feature.widgetAguaSilencioso,
///   child: MinhaFeaturePro(),
/// )
/// ```
class FeatureGate extends StatelessWidget {
  final Feature feature;
  final Widget child;
  final String? tituloBloqueio;
  final IconData icone;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.tituloBloqueio,
    this.icone = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (ctx, premium, _) {
        if (FeaturePolicy.liberado(feature, premium: premium.isPremium)) {
          return child;
        }
        return _bloqueioCard(context);
      },
    );
  }

  Widget _bloqueioCard(BuildContext context) {
    final titulo = tituloBloqueio ?? 'Disponível no Recorpo Premium';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.azulClinico.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.azulClinico.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.azulClinico,
              foregroundColor: Colors.white,
              child: Icon(icone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Toque para ver os planos',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const _ProBadge(),
          ],
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.verdeConfirma,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Helper para telas inteiras. Substitui a rota destino por um "empurra
/// pra Paywall" se o usuário for Free.
class FeatureGuard {
  static bool checar(BuildContext context, Feature f, {bool empurrarPaywall = true}) {
    final premium = context.read<PremiumService>();
    final liberado = FeaturePolicy.liberado(f, premium: premium.isPremium);
    if (!liberado && empurrarPaywall) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
    return liberado;
  }
}
