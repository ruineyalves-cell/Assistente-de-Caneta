import 'dart:convert' show jsonDecode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../services/logs_provider.dart';
import '../../utils/theme.dart' show EixoRecorpo;
import '../../widgets/eixo_card.dart';
import '../../widgets/symptoms_sheet.dart';
import '../../widgets/weight_quick_sheet.dart';

/// Linha Peso + Sintomas da grade da Home.
///
/// Fase 3 — mesmo padrão de referência de `home_consistencia_row.dart`:
/// cada card é um `Selector<LogsProvider,…>` + `RepaintBoundary`, então só
/// reconstrói quando o SEU dado muda (não a cada `notifyListeners`, ex.:
/// encher água não repinta peso nem sintomas). Peso e sintomas derivam só
/// de `logs` (não dependem do perfil), então a linha inteira é `const`.
///
/// A lógica de derivação fica em funções puras (`derivarPeso` /
/// `derivarSintomasHoje`) — idênticas ao builder original — pra poderem
/// ser cobertas por unit test.
class HomePesoSintomasRow extends StatelessWidget {
  const HomePesoSintomasRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _PesoSelector()),
        SizedBox(width: 12),
        Expanded(child: _SintomasSelector()),
      ],
    );
  }
}

/// Peso mais recente + variação vs. o penúltimo registro COM peso.
/// Idêntica à lógica original da DashboardPage.
({double? atual, double? delta}) derivarPeso(List<DailyLog> logs) {
  final comPeso = logs.where((l) => l.pesoKg != null).toList();
  final atual = comPeso.isNotEmpty ? comPeso.first.pesoKg : null;
  final anterior = comPeso.length > 1 ? comPeso[1].pesoKg : null;
  final delta = (atual != null && anterior != null) ? atual - anterior : null;
  return (atual: atual, delta: delta);
}

/// Total de sintomas registrados HOJE (soma os itens do array `sintomas`
/// no JSON de efeitos dos logs de hoje). `agora` é injetável pra testes.
int derivarSintomasHoje(List<DailyLog> logs, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  var total = 0;
  for (final l in logs) {
    if (l.data.year != hoje.year ||
        l.data.month != hoje.month ||
        l.data.day != hoje.day) {
      continue;
    }
    final efeitos = l.efeitosColaterais;
    if (efeitos == null || efeitos.isEmpty) continue;
    try {
      final j = jsonDecode(efeitos);
      if (j is Map && j['sintomas'] is List) {
        total += (j['sintomas'] as List).length;
      }
    } catch (_) {
      /* JSON inválido — ignora, como no original */
    }
  }
  return total;
}

class _PesoSelector extends StatelessWidget {
  const _PesoSelector();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Selector<LogsProvider, ({double? atual, double? delta})>(
        selector: (_, p) => derivarPeso(p.logs),
        builder: (context, peso, __) {
          final atual = peso.atual;
          final delta = peso.delta;
          return EixoCard(
            eixo: EixoRecorpo.peso,
            titulo: 'Peso',
            valor: atual == null ? '—' : atual.toStringAsFixed(1),
            subtitulo: atual == null
                ? 'Sem registro'
                : delta == null
                    ? 'kg (primeiro registro)'
                    : delta < 0
                        ? 'kg · ${delta.toStringAsFixed(1)} vs último'
                        : 'kg · +${delta.toStringAsFixed(1)} vs último',
            rodape: 'Toque para registrar',
            onTap: () => mostrarWeightQuickSheet(context, pesoAnteriorKg: atual),
          );
        },
      ),
    );
  }
}

class _SintomasSelector extends StatelessWidget {
  const _SintomasSelector();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Selector<LogsProvider, int>(
        selector: (_, p) => derivarSintomasHoje(p.logs),
        builder: (context, sintomasHoje, __) {
          return EixoCard(
            eixo: EixoRecorpo.sintomas,
            titulo: 'Sintomas',
            valor: sintomasHoje == 0 ? 'OK' : '$sintomasHoje',
            subtitulo: sintomasHoje == 0
                ? 'Nada registrado hoje'
                : sintomasHoje == 1
                    ? '1 registrado hoje'
                    : '$sintomasHoje registrados hoje',
            rodape: 'Como você está?',
            onTap: () => abrirSymptomsSheet(context),
          );
        },
      ),
    );
  }
}
