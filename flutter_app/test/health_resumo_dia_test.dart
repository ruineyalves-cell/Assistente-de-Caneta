// Unit tests do HealthResumoDia — o modelo de dados do Health Connect
// que alimenta o card Movimento e o card Sono no dashboard (Lote 32.1).
// Não exercita o plugin nativo — só a lógica do modelo.
import 'package:flutter_test/flutter_test.dart';
import 'package:assistente_caneta/services/health_connect_service.dart';

void main() {
  group('HealthResumoDia.temDados', () {
    test('vazio → temDados = false', () {
      expect(HealthResumoDia.vazio.temDados, isFalse);
    });

    test('só com passos > 0 → temDados = true', () {
      const r = HealthResumoDia(passos: 4200);
      expect(r.temDados, isTrue);
    });

    test('passos = 0 e sem outros dados → temDados = false', () {
      const r = HealthResumoDia(passos: 0);
      expect(r.temDados, isFalse);
    });

    test('só peso via balança smart → temDados = true', () {
      final r = HealthResumoDia(
        pesoUltimoKg: 87.2,
        pesoUltimoEm: DateTime(2026, 7, 19, 8, 0),
      );
      expect(r.temDados, isTrue);
    });

    test('só sono → temDados = true', () {
      const r = HealthResumoDia(sonoMinutos: 420); // 7h
      expect(r.temDados, isTrue);
    });

    test('sono = 0 não conta como dado', () {
      const r = HealthResumoDia(sonoMinutos: 0);
      expect(r.temDados, isFalse);
    });

    test('só amostras de bpm > 0 → temDados = true', () {
      const r = HealthResumoDia(bpmMedio: 72, amostrasBpm: 5);
      expect(r.temDados, isTrue);
    });
  });

  group('HealthResumoDia — retenção de campos', () {
    test('todos os campos preservados no construtor', () {
      final agora = DateTime(2026, 7, 19, 8, 30);
      final r = HealthResumoDia(
        bpmMedio: 68,
        bpmMax: 128,
        kcalAtivas: 320.5,
        passos: 8420,
        pesoUltimoKg: 87.2,
        pesoUltimoEm: agora,
        sonoMinutos: 445,
        amostrasBpm: 12,
        amostrasKcal: 3,
      );
      expect(r.bpmMedio, 68);
      expect(r.bpmMax, 128);
      expect(r.kcalAtivas, closeTo(320.5, 0.01));
      expect(r.passos, 8420);
      expect(r.pesoUltimoKg, closeTo(87.2, 0.01));
      expect(r.pesoUltimoEm, agora);
      expect(r.sonoMinutos, 445);
      expect(r.amostrasBpm, 12);
      expect(r.amostrasKcal, 3);
    });
  });
}
