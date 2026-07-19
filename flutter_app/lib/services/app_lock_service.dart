import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lote 32.5 — Bloqueio do app com PIN + biometria.
///
/// Requisito de dados de saúde (Play Store BR 2026 exige bloqueio
/// opcional em apps clínicos). Dois fatores:
///  1. PIN de 4-6 dígitos, armazenado como hash SHA-256 no
///     `flutter_secure_storage` (Keychain/EncryptedSharedPreferences).
///  2. Biometria opt-in via `local_auth` (fingerprint/face).
///
/// A tela de unlock tenta biometria primeiro (se ligada) e usa o PIN
/// como fallback. Erros incrementam um contador em prefs — passou de 5
/// erros consecutivos, congela por 30s e reseta.
///
/// Auto-lock: `MyApp` observa `AppLifecycleState.paused` e registra o
/// timestamp. Na volta (`resumed`), se passou `timeoutSegundos`, marca
/// como travado e o gate mostra `AppLockScreen`.
class AppLockService extends ChangeNotifier {
  final FlutterSecureStorage _secure;
  final LocalAuthentication _auth;
  final SharedPreferences _prefs;

  // Chaves — secure storage guarda apenas o hash + salt.
  static const _keyHash = 'app_lock_pin_hash_v1';
  static const _keySalt = 'app_lock_pin_salt_v1';

  // Prefs — configurações não-sensíveis.
  static const _keyBiometriaOn = 'app_lock_biometria_v1';
  static const _keyTimeoutSeg = 'app_lock_timeout_seg_v1';
  static const _keyBackgroundedEm = 'app_lock_bg_epoch_v1';
  static const _keyTentativasErradas = 'app_lock_tentativas_v1';
  static const _keyBloqueadoAte = 'app_lock_bloqueado_ate_v1';

  /// Timeouts pré-definidos exibidos na tela de setup.
  static const List<int> timeoutsDisponiveisSeg = [0, 60, 300, 900];

  bool _configurado = false;
  bool _travado = false;
  bool _biometriaHabilitada = false;
  int _timeoutSeg = 300; // 5 min default

  AppLockService._(this._secure, this._auth, this._prefs);

  static Future<AppLockService> criar({
    FlutterSecureStorage? secure,
    LocalAuthentication? auth,
    SharedPreferences? prefs,
  }) async {
    final s = secure ?? const FlutterSecureStorage();
    final a = auth ?? LocalAuthentication();
    final p = prefs ?? await SharedPreferences.getInstance();
    final svc = AppLockService._(s, a, p);
    await svc._carregar();
    return svc;
  }

  bool get configurado => _configurado;
  bool get travado => _travado;
  bool get biometriaHabilitada => _biometriaHabilitada;
  int get timeoutSeg => _timeoutSeg;
  bool get suportado => !kIsWeb;

  Future<void> _carregar() async {
    final hash = await _secure.read(key: _keyHash);
    _configurado = hash != null && hash.isNotEmpty;
    _biometriaHabilitada = _prefs.getBool(_keyBiometriaOn) ?? false;
    _timeoutSeg = _prefs.getInt(_keyTimeoutSeg) ?? 300;
    // No boot, se há PIN configurado o app começa travado.
    _travado = _configurado;
  }

  // ─────────────────────────────────────────────────────────────
  // Setup / troca de PIN
  // ─────────────────────────────────────────────────────────────

  bool pinValido(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  Future<void> definirPin(String pin) async {
    if (!pinValido(pin)) {
      throw ArgumentError('PIN deve ter 4 a 6 dígitos numéricos.');
    }
    final salt = _gerarSalt();
    final hash = _hashPin(pin, salt);
    await _secure.write(key: _keyHash, value: hash);
    await _secure.write(key: _keySalt, value: salt);
    await _prefs.remove(_keyTentativasErradas);
    await _prefs.remove(_keyBloqueadoAte);
    _configurado = true;
    _travado = false;
    notifyListeners();
  }

  Future<void> desativar(String pinAtual) async {
    if (!await verificarPin(pinAtual)) {
      throw StateError('PIN incorreto.');
    }
    await _secure.delete(key: _keyHash);
    await _secure.delete(key: _keySalt);
    await _prefs.setBool(_keyBiometriaOn, false);
    _configurado = false;
    _biometriaHabilitada = false;
    _travado = false;
    notifyListeners();
  }

  Future<void> definirBiometria(bool habilitar) async {
    if (habilitar) {
      final ok = await _biometriaDisponivel();
      if (!ok) {
        throw StateError('Biometria indisponível neste dispositivo.');
      }
    }
    await _prefs.setBool(_keyBiometriaOn, habilitar);
    _biometriaHabilitada = habilitar;
    notifyListeners();
  }

  Future<void> definirTimeout(int segundos) async {
    if (!timeoutsDisponiveisSeg.contains(segundos)) {
      throw ArgumentError('Timeout não suportado.');
    }
    await _prefs.setInt(_keyTimeoutSeg, segundos);
    _timeoutSeg = segundos;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Unlock
  // ─────────────────────────────────────────────────────────────

  int get tentativasErradas => _prefs.getInt(_keyTentativasErradas) ?? 0;

  DateTime? get bloqueadoAte {
    final ms = _prefs.getInt(_keyBloqueadoAte);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get estaTemporariamenteBloqueado {
    final ate = bloqueadoAte;
    return ate != null && ate.isAfter(DateTime.now());
  }

  Future<bool> verificarPin(String pin) async {
    if (estaTemporariamenteBloqueado) return false;
    final hash = await _secure.read(key: _keyHash);
    final salt = await _secure.read(key: _keySalt);
    if (hash == null || salt == null) return false;
    final proposto = _hashPin(pin, salt);
    if (proposto == hash) {
      await _prefs.remove(_keyTentativasErradas);
      await _prefs.remove(_keyBloqueadoAte);
      _travado = false;
      notifyListeners();
      return true;
    }
    final atuais = tentativasErradas + 1;
    await _prefs.setInt(_keyTentativasErradas, atuais);
    if (atuais >= 5) {
      final ate = DateTime.now().add(const Duration(seconds: 30));
      await _prefs.setInt(_keyBloqueadoAte, ate.millisecondsSinceEpoch);
      await _prefs.remove(_keyTentativasErradas);
    }
    return false;
  }

  /// Tenta desbloquear via biometria. Retorna `false` se biometria
  /// desabilitada, indisponível, ou o usuário cancelou.
  Future<bool> tentarBiometria({String razao = 'Desbloquear Recorpo'}) async {
    if (!_biometriaHabilitada) return false;
    if (!suportado) return false;
    try {
      final ok = await _auth.authenticate(
        localizedReason: razao,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) {
        _travado = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _biometriaDisponivel() async {
    if (!suportado) return false;
    try {
      final suportadoPeloOS = await _auth.isDeviceSupported();
      final podeBio = await _auth.canCheckBiometrics;
      final tipos = await _auth.getAvailableBiometrics();
      return suportadoPeloOS && podeBio && tipos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> biometriaDisponivel() => _biometriaDisponivel();

  // ─────────────────────────────────────────────────────────────
  // Auto-lock (lifecycle)
  // ─────────────────────────────────────────────────────────────

  /// Chamado quando o app vai pra background. Registra o instante.
  Future<void> marcarBackground() async {
    if (!_configurado) return;
    await _prefs.setInt(
      _keyBackgroundedEm,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Chamado ao voltar pro foreground. Se passou do timeout, trava.
  Future<void> avaliarForeground() async {
    if (!_configurado) return;
    if (_timeoutSeg == 0) {
      // Trava imediato — qualquer troca de foreground bloqueia.
      _travado = true;
      notifyListeners();
      return;
    }
    final ms = _prefs.getInt(_keyBackgroundedEm);
    if (ms == null) return;
    final quando = DateTime.fromMillisecondsSinceEpoch(ms);
    final ausenteSeg = DateTime.now().difference(quando).inSeconds;
    if (ausenteSeg >= _timeoutSeg) {
      _travado = true;
      notifyListeners();
    }
  }

  /// Força bloqueio (usado no logout ou no botão "bloquear agora").
  void bloquearAgora() {
    if (!_configurado) return;
    _travado = true;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Hash
  // ─────────────────────────────────────────────────────────────

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt|$pin');
    return sha256.convert(bytes).toString();
  }

  static String _gerarSalt() {
    final micro = DateTime.now().microsecondsSinceEpoch.toString();
    final rand = (DateTime.now().hashCode ^ micro.hashCode).toString();
    return sha256.convert(utf8.encode('$micro-$rand')).toString();
  }
}
