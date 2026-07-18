import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../utils/constants.dart';

/// Tela de assinatura Premium — Play Billing.
///
/// Se o Play Billing não estiver disponível (dev/QA em máquina sem Play
/// Store, ou primeira execução antes de o usuário configurar os SKUs no
/// Play Console), a tela mostra as vantagens em modo "vitrine" com um
/// aviso amigável.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _vantagens = <(IconData, String)>[
    (Icons.photo_camera_outlined, 'Câmera e OCR ilimitados'),
    (Icons.picture_as_pdf_outlined, 'PDF pro médico ilimitado'),
    (Icons.water_drop_outlined, 'Widget de água silencioso na tela'),
    (Icons.query_stats, 'Comparativos 30 / 60 / 90 dias'),
    (Icons.celebration_outlined, 'Notificações e celebrações completas'),
    (Icons.trending_up, 'Ajuste de esforço detalhado'),
    (Icons.block, 'Sem anúncios (quando adicionarmos no Free)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorpo Premium'),
        elevation: 0,
        backgroundColor: AppColors.fundoFrio,
      ),
      backgroundColor: AppColors.fundoFrio,
      body: SafeArea(
        child: Consumer<PremiumService>(
          builder: (context, premium, _) {
            if (premium.isPremium) {
              return _jaEhPremium(context);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hero(),
                  const SizedBox(height: 24),
                  ..._vantagens.map((v) => _linhaBeneficio(v.$1, v.$2)),
                  const SizedBox(height: 24),
                  if (!premium.billingDisponivel)
                    _avisoBillingIndisponivel()
                  else if (premium.produtos.isEmpty)
                    _carregandoOuSemProdutos()
                  else
                    _planos(context, premium),
                  const SizedBox(height: 20),
                  Text(
                    'Assinatura renova automaticamente. Cancele a qualquer '
                    'momento na Play Store. Sem taxa de saída.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _jaEhPremium(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium,
                size: 96, color: AppColors.verdeConfirma),
            const SizedBox(height: 16),
            const Text('Você é Premium 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Aproveite todas as features do Recorpo sem limite.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar ao app'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.azulClinico, Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 36),
          SizedBox(height: 12),
          Text(
            'Desbloqueie o Recorpo por completo',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Menos que 1 café gourmet por mês. Você cuida da sua saúde.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _linhaBeneficio(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, color: AppColors.azulClinico, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
          const Icon(Icons.check_circle, color: AppColors.verdeConfirma, size: 20),
        ],
      ),
    );
  }

  Widget _avisoBillingIndisponivel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: Colors.amber),
          SizedBox(height: 8),
          Text(
            'A assinatura ainda não está disponível nesta versão. '
            'Assim que o Recorpo estiver publicado na Play Store, você '
            'poderá assinar por aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _carregandoOuSemProdutos() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _planos(BuildContext context, PremiumService premium) {
    ProductDetails? mensal;
    ProductDetails? anual;
    for (final p in premium.produtos) {
      if (p.id == PremiumService.kSkuMensal) mensal = p;
      if (p.id == PremiumService.kSkuAnual) anual = p;
    }

    return Column(
      children: [
        if (anual != null)
          _cardPlano(
            context,
            premium,
            produto: anual,
            titulo: 'Anual',
            destaque: 'Melhor valor',
            economia: '37% de economia',
          ),
        if (anual != null && mensal != null) const SizedBox(height: 12),
        if (mensal != null)
          _cardPlano(
            context,
            premium,
            produto: mensal,
            titulo: 'Mensal',
            destaque: null,
            economia: null,
          ),
      ],
    );
  }

  Widget _cardPlano(
    BuildContext context,
    PremiumService premium, {
    required ProductDetails produto,
    required String titulo,
    required String? destaque,
    required String? economia,
  }) {
    final ehDestaque = destaque != null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: premium.carregando ? null : () => premium.comprar(produto),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ehDestaque
                ? AppColors.verdeConfirma
                : Colors.grey.shade300,
            width: ehDestaque ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                if (destaque != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.verdeConfirma,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(destaque,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
                const Spacer(),
                Text(produto.price,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            if (economia != null) ...[
              const SizedBox(height: 4),
              Text(economia,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2F855A), // verde escuro
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
