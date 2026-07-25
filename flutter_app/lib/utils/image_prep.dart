import 'dart:convert' show base64Encode;
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compressão + resize das fotos ANTES de enviar pra IA (Lote P1).
///
/// Câmera moderna (S25) gera ~4-8 MB por foto. Base64 disso é ~10 MB,
/// quebra o body limit do backend e demora 20+ segundos em 4G.
/// Aqui reduzimos para JPEG q=80 no lado maior de 1280 px — o Gemini
/// não precisa de mais que isso pra ler rótulo/bula e continua
/// reconhecendo prato de comida sem perda perceptível.
///
/// Retorna já em base64 pronto pro payload.
class ImagePrep {
  static const int _maxLadoPx = 1280;
  static const int _qualidade = 80;

  /// Comprime a imagem no disco e devolve base64.
  static Future<String> prepararParaIA(File arquivo) async {
    try {
      final bytes = await FlutterImageCompress.compressWithFile(
        arquivo.absolute.path,
        minWidth: _maxLadoPx,
        minHeight: _maxLadoPx,
        quality: _qualidade,
        format: CompressFormat.jpeg,
        keepExif: false, // remove metadados de GPS/câmera (privacidade)
      );
      if (bytes == null) {
        // Fallback: sem compressão, mas ainda funciona.
        return base64Encode(await arquivo.readAsBytes());
      }
      return base64Encode(bytes);
    } catch (_) {
      return base64Encode(await arquivo.readAsBytes());
    }
  }
}
