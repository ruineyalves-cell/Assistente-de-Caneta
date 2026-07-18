import 'dart:convert' show base64Encode;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'api_service.dart';

/// Lote 21 — Reconhecimento de comida na foto.
///
/// Duas camadas independentes:
///   1) LOCAL (on-device, sem chave, sempre funciona no Android): usa
///      Google ML Kit Image Labeling e devolve labels tipo "Food",
///      "Vegetable", "Salad", "Meat", com confiança. É rápido e
///      privado, mas grosseiro.
///   2) BACKEND (opcional; só ativa depois de o usuário configurar):
///      chama POST /api/ia/refeicao com base64 da foto. O backend
///      decide qual IA usar (OpenAI Vision, Gemini, etc.) conforme
///      OPENAI_API_KEY / GEMINI_API_KEY no Render.
///
/// Estratégia de UX: mostra os labels locais imediatamente e, em
/// paralelo, dispara a análise no backend. Se o backend responder com
/// uma descrição melhor (nome dos pratos, proteína estimada), a UI
/// atualiza. Se falhar, o usuário fica com o resultado local.
class MealRecognitionService {
  final ApiService _api;

  MealRecognitionService(this._api);

  /// Roda ML Kit Image Labeling on-device. Filtra pra tópicos ligados a
  /// comida — o modelo genérico devolve muita coisa que não interessa
  /// (mobiliário, pessoas, etc).
  Future<List<MealLabel>> reconhecerLocal(File imagem) async {
    if (kIsWeb) return const [];
    final input = InputImage.fromFilePath(imagem.path);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
    try {
      final labels = await labeler.processImage(input);
      final relevantes = labels
          .where((l) => _foodLike(l.label))
          .map((l) => MealLabel(
                label: l.label,
                labelPtBr: _traduzir(l.label),
                confidence: l.confidence,
              ))
          .toList();
      relevantes.sort((a, b) => b.confidence.compareTo(a.confidence));
      return relevantes.take(6).toList();
    } finally {
      await labeler.close();
    }
  }

  /// Chama o backend, que decide se usa OpenAI/Gemini ou devolve um
  /// stub educado. Retorna `null` se o backend não estiver configurado
  /// pra IA — nesse caso a UI segue só com o local.
  Future<MealAiResult?> analisarNoBackend(File imagem) async {
    try {
      final bytes = await imagem.readAsBytes();
      final resp = await _api.analisarRefeicaoIA(
        imagemBase64: base64Encode(bytes),
      );
      if (resp['iaConfigurada'] == false) return null;
      return MealAiResult(
        titulo: resp['titulo'] as String?,
        descricao: resp['descricao'] as String?,
        proteinaEstimadaG: (resp['proteinaEstimadaG'] as num?)?.toInt(),
        aguaEstimadaMl: (resp['aguaEstimadaMl'] as num?)?.toInt(),
        confianca: (resp['confianca'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  bool _foodLike(String label) {
    final l = label.toLowerCase();
    const chaves = <String>[
      'food', 'fruit', 'vegetable', 'salad', 'meat', 'seafood', 'fish',
      'chicken', 'beef', 'pork', 'egg', 'bread', 'rice', 'pasta', 'noodle',
      'soup', 'stew', 'dessert', 'cake', 'pie', 'cheese', 'yogurt', 'milk',
      'drink', 'juice', 'coffee', 'tea', 'water', 'wine', 'beer', 'dish',
      'meal', 'breakfast', 'lunch', 'dinner', 'snack', 'produce', 'plant',
    ];
    return chaves.any((k) => l.contains(k));
  }

  String _traduzir(String label) {
    const dic = <String, String>{
      'Food': 'Comida',
      'Fruit': 'Fruta',
      'Vegetable': 'Vegetal',
      'Salad': 'Salada',
      'Meat': 'Carne',
      'Seafood': 'Frutos do mar',
      'Fish': 'Peixe',
      'Chicken': 'Frango',
      'Beef': 'Carne bovina',
      'Pork': 'Porco',
      'Egg': 'Ovo',
      'Bread': 'Pão',
      'Rice': 'Arroz',
      'Pasta': 'Massa',
      'Noodle': 'Macarrão',
      'Soup': 'Sopa',
      'Stew': 'Ensopado',
      'Dessert': 'Sobremesa',
      'Cheese': 'Queijo',
      'Yogurt': 'Iogurte',
      'Milk': 'Leite',
      'Drink': 'Bebida',
      'Juice': 'Suco',
      'Coffee': 'Café',
      'Tea': 'Chá',
      'Water': 'Água',
      'Dish': 'Prato',
      'Meal': 'Refeição',
      'Breakfast': 'Café da manhã',
      'Lunch': 'Almoço',
      'Dinner': 'Jantar',
      'Snack': 'Lanche',
      'Produce': 'Alimento natural',
      'Plant': 'Planta',
    };
    return dic[label] ?? label;
  }
}

class MealLabel {
  final String label;
  final String labelPtBr;
  final double confidence;
  const MealLabel({
    required this.label,
    required this.labelPtBr,
    required this.confidence,
  });
}

class MealAiResult {
  final String? titulo;
  final String? descricao;
  final int? proteinaEstimadaG;
  final int? aguaEstimadaMl;
  final double? confianca;
  const MealAiResult({
    this.titulo,
    this.descricao,
    this.proteinaEstimadaG,
    this.aguaEstimadaMl,
    this.confianca,
  });
}

