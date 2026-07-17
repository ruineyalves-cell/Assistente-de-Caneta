import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Meta nutricional detectada no OCR de uma prescrição.
class MetaDetectada {
  /// Categoria da meta (ex.: "Proteína", "Hidratação", "Calorias").
  final String categoria;

  /// Trecho literal do texto reconhecido que gerou a detecção.
  final String trecho;

  const MetaDetectada({required this.categoria, required this.trecho});
}

/// Resultado bruto + interpretado da leitura OCR.
class OcrPrescricaoResultado {
  final String textoCompleto;
  final List<MetaDetectada> metas;

  const OcrPrescricaoResultado({
    required this.textoCompleto,
    required this.metas,
  });
}

/// Roda o Google ML Kit Text Recognition (on-device, sem chamada de rede)
/// sobre uma imagem de prescrição nutricional e devolve o texto lido +
/// as metas nutricionais destacadas por heurísticas simples de regex.
///
/// Nenhuma decisão clínica é feita aqui — o objetivo do Lote 10 é
/// **entregar o texto ao paciente** e destacar visualmente o que parece
/// ser uma meta, para ele conferir com quem prescreveu.
class PrescriptionOcrService {
  final TextRecognizer _recognizer;

  PrescriptionOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  /// Reconhece o texto do caminho de imagem informado e destaca metas.
  Future<OcrPrescricaoResultado> lerCaminho(String caminho) async {
    final input = InputImage.fromFilePath(caminho);
    final resultado = await _recognizer.processImage(input);
    final texto = resultado.text;
    return OcrPrescricaoResultado(
      textoCompleto: texto,
      metas: detectarMetas(texto),
    );
  }

  /// Fecha o TextRecognizer — chame ao dispose da tela para liberar o
  /// modelo carregado em memória.
  Future<void> fechar() => _recognizer.close();

  // ---------- heurísticas (públicas para permitir teste) ----------

  /// Extrai metas nutricionais do texto lido. A abordagem é tolerante:
  /// para cada linha, se ela **contém** uma palavra-chave da categoria
  /// **e** um número seguido de uma unidade compatível, considera
  /// detectada. Isso funciona nas duas ordens: "Proteína: 120 g" e
  /// "120 g de proteína".
  static List<MetaDetectada> detectarMetas(String texto) {
    final metas = <MetaDetectada>[];
    for (final linha in _linhasLimpas(texto)) {
      _classificarLinha(linha, metas);
    }
    return metas;
  }

  static void _classificarLinha(String linha, List<MetaDetectada> destino) {
    // Calorias: número (3–5 dígitos) + kcal/calorias em qualquer ordem.
    if (_temUnidade(linha, _unidadesKcal) &&
        _temNumero(linha, minDigitos: 3)) {
      destino.add(MetaDetectada(categoria: 'Calorias', trecho: linha));
    }
    // As demais categorias exigem unidade `g`/`ml`/`L` + palavra-chave.
    final ehGrama = _temUnidade(linha, _unidadesGrama);
    final ehLiquido = _temUnidade(linha, _unidadesLiquido);
    final temNum = _temNumero(linha);

    if (temNum && ehGrama && _temQualquer(linha, _kwProteina)) {
      destino.add(MetaDetectada(categoria: 'Proteína', trecho: linha));
    }
    if (temNum && ehGrama && _temQualquer(linha, _kwCarbo)) {
      destino.add(MetaDetectada(categoria: 'Carboidratos', trecho: linha));
    }
    if (temNum && ehGrama && _temQualquer(linha, _kwGordura)) {
      destino.add(MetaDetectada(categoria: 'Gordura', trecho: linha));
    }
    if (temNum && ehLiquido && _temQualquer(linha, _kwAgua)) {
      destino.add(MetaDetectada(categoria: 'Hidratação', trecho: linha));
    }
  }

  // -------- vocabulários ----------
  static final _kwProteina = [
    RegExp(r'prote[ií]na', caseSensitive: false),
    RegExp(r'prote[ií]c', caseSensitive: false), // proteica/proteico
  ];
  static final _kwCarbo = [
    RegExp(r'carboidrato', caseSensitive: false),
    RegExp(r'\bcarbo\b', caseSensitive: false),
  ];
  static final _kwGordura = [
    RegExp(r'gordur', caseSensitive: false),
    RegExp(r'l[ií]p[ií]d', caseSensitive: false), // lipid, lipíd, lípid
  ];
  // Word boundaries \b não confiam em caracteres acentuados; usamos lookaround
  // com [^A-Za-zÀ-ÿ] ou apenas contains sem boundary (mais tolerante).
  static final _kwAgua = [
    RegExp(r'(^|[^A-Za-zÀ-ÿ])ág?ua', caseSensitive: false),
    RegExp(r'hidrat', caseSensitive: false),
    RegExp(r'l[ií]quido', caseSensitive: false),
    RegExp(r'h[ií]drica', caseSensitive: false),
    RegExp(r'ingest', caseSensitive: false),
  ];

  static final _unidadesGrama =
      RegExp(r'\d+([\.,]\d+)?\s*(g|gr|gramas?)(?:/kg)?\b', caseSensitive: false);
  static final _unidadesLiquido =
      RegExp(r'\d+([\.,]\d+)?\s*(ml|l|litros?)\b', caseSensitive: false);
  static final _unidadesKcal =
      RegExp(r'\b\d{3,5}\s*(kcal|calorias?)\b', caseSensitive: false);

  static bool _temNumero(String linha, {int minDigitos = 1}) {
    final r = RegExp('\\d{$minDigitos,}');
    return r.hasMatch(linha);
  }

  static bool _temUnidade(String linha, RegExp unidade) =>
      unidade.hasMatch(linha);

  static bool _temQualquer(String linha, List<RegExp> padroes) {
    for (final p in padroes) {
      if (p.hasMatch(linha)) return true;
    }
    return false;
  }

  static Iterable<String> _linhasLimpas(String texto) sync* {
    for (final raw in texto.split(RegExp(r'[\r\n]+'))) {
      final l = raw.trim();
      if (l.isNotEmpty) yield l;
    }
  }
}
