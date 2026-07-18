import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lote 20/23 — Cérebro do Free/Pro do Recorpo.
///
/// Estado é derivado de 3 fontes, na ordem:
///   1) Assinatura ativa no Play Billing (source of truth em produção)
///   2) Flag manual persistida (backdoor de dev/QA e de trial)
///   3) Padrão = Free
///
/// Fica DESATIVADO em plataformas que não suportam Play Billing (web, iOS
/// enquanto Apple Pay não estiver configurado). Nesses casos permanece
/// Free, e as gates cobram normalmente.
class PremiumService extends ChangeNotifier {
  static const kSkuMensal = 'recorpo_premium_monthly';
  static const kSkuAnual = 'recorpo_premium_yearly';
  static const _kPrefsPremiumDev = 'recorpo_premium_dev_override';
  static const _kPrefsUltimaCompra = 'recorpo_premium_last_purchase_epoch';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _isPremium = false;
  bool _iapDisponivel = false;
  bool _carregando = false;
  List<ProductDetails> _produtos = const [];
  String? _erro;

  bool get isPremium => _isPremium;
  bool get isFree => !_isPremium;
  bool get billingDisponivel => _iapDisponivel;
  bool get carregando => _carregando;
  List<ProductDetails> get produtos => _produtos;
  String? get erro => _erro;

  /// Ponto de entrada. Chamar UMA vez no boot do app.
  Future<void> inicializar() async {
    if (kIsWeb) {
      _isPremium = await _lerFlagDev();
      notifyListeners();
      return;
    }
    try {
      _iapDisponivel = await _iap.isAvailable();
    } catch (_) {
      _iapDisponivel = false;
    }

    _isPremium = await _lerFlagDev();

    if (_iapDisponivel) {
      _sub = _iap.purchaseStream.listen(
        _processarCompras,
        onError: (Object e) {
          _erro = e.toString();
          notifyListeners();
        },
      );
      await _carregarProdutos();
      // Restaura compras existentes (usuário reinstalou / trocou de aparelho)
      await _iap.restorePurchases();
    }
    notifyListeners();
  }

  Future<void> _carregarProdutos() async {
    final ids = <String>{kSkuMensal, kSkuAnual};
    try {
      final resposta = await _iap.queryProductDetails(ids);
      _produtos = resposta.productDetails;
    } catch (e) {
      _erro = e.toString();
    }
  }

  /// Fluxo real de compra. Retorna `true` se o compra_stream aceitou;
  /// a confirmação de entitlement chega via [purchaseStream] depois.
  Future<bool> comprar(ProductDetails produto) async {
    if (!_iapDisponivel) return false;
    _carregando = true;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: produto);
      // Assinatura → buyNonConsumable (o próprio Play controla renovação)
      return await _iap.buyNonConsumable(purchaseParam: param);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> _processarCompras(List<PurchaseDetails> lista) async {
    var virou = false;
    for (final p in lista) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == kSkuMensal || p.productID == kSkuAnual) {
          virou = true;
        }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    if (virou && !_isPremium) {
      _isPremium = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _kPrefsUltimaCompra, DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
    }
  }

  /// Backdoor para desenvolvimento / QA / gift codes. Só afeta o binário
  /// local; a Play Store continua sendo a fonte de verdade em produção.
  Future<void> setPremiumDev(bool valor) async {
    _isPremium = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsPremiumDev, valor);
    notifyListeners();
  }

  Future<bool> _lerFlagDev() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrefsPremiumDev) ?? false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Enum das features controladas por paywall. Central pra evitar strings
/// mágicas espalhadas nos widgets.
enum Feature {
  cameraRefeicao,
  ocrPrescricao,
  widgetAguaSilencioso,
  pdfMedico,
  comparativoHistorico90d,
  notificacoesCelebracao,
  ajusteEsforcoAvancado,
}

/// Regras de acesso Free/Pro. Fonte única — trocar aqui muda o app todo.
class FeaturePolicy {
  static bool liberado(Feature f, {required bool premium}) {
    if (premium) return true;
    // Regras do Free: alguns liberados com quota (a quota fica no chamador,
    // aqui é só sim/não para o paywall).
    switch (f) {
      case Feature.cameraRefeicao:
        return true; // Free: 1x/dia (quota controlada em outro lugar)
      case Feature.ocrPrescricao:
        return true; // Free: 1x/semana
      case Feature.widgetAguaSilencioso:
        return false;
      case Feature.pdfMedico:
        return true; // Free: 1x/mês
      case Feature.comparativoHistorico90d:
        return false; // Free só vê 30 dias
      case Feature.notificacoesCelebracao:
        return true;
      case Feature.ajusteEsforcoAvancado:
        return false;
    }
  }

  /// Quotas do Free por período. Retorna null para features Pro-only.
  static ({int limite, Duration periodo})? quotaFree(Feature f) {
    switch (f) {
      case Feature.cameraRefeicao:
        return (limite: 1, periodo: const Duration(days: 1));
      case Feature.ocrPrescricao:
        return (limite: 1, periodo: const Duration(days: 7));
      case Feature.pdfMedico:
        return (limite: 1, periodo: const Duration(days: 30));
      default:
        return null;
    }
  }
}
