import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';

/// Lote 32.2 — Tela "Preparar consulta".
///
/// Consome `GET /api/pacientes/pre-consulta`. Zero IA — mostra fatos
/// objetivos dos últimos 30 dias + até 5 perguntas curadas.
///
/// Design guiado por 3 princípios:
///  1. Disclaimer legal explícito no topo e no rodapé.
///  2. Fatos numéricos primeiro (isso é seu, é objetivo).
///  3. Perguntas depois, cada uma com referência à fonte pública
///     (Bula Anvisa, ABESO, ADA, OMS).
class PreConsultaScreen extends StatefulWidget {
  const PreConsultaScreen({super.key});

  @override
  State<PreConsultaScreen> createState() => _PreConsultaScreenState();
}

class _PreConsultaScreenState extends State<PreConsultaScreen> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _dados;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final auth = context.read<AuthService>();
    try {
      final dados = await auth.apiService.obterPreConsulta();
      if (!mounted) return;
      setState(() {
        _dados = dados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _copiarParaCompartilhar() async {
    final texto = _montarTextoCompartilhavel();
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado. Cole no WhatsApp, email ou onde preferir.'),
      ),
    );
  }

  String _montarTextoCompartilhavel() {
    final d = _dados;
    if (d == null) return '';
    final fatos = d['fatos'] as Map<String, dynamic>;
    final perguntas = (d['perguntas'] as List).cast<Map<String, dynamic>>();
    final peso = fatos['peso'] as Map<String, dynamic>;
    final dose = fatos['dose'] as Map<String, dynamic>;
    final top = (fatos['topSintomas'] as List).cast<Map<String, dynamic>>();

    final buf = StringBuffer()
      ..writeln('*Recorpo — resumo dos últimos ${fatos['janelaDias']} dias*')
      ..writeln();

    if (peso['atual'] != null) {
      buf.writeln('• Peso atual: ${peso['atual']} kg');
      if (peso['variacaoKg'] != null) {
        buf.writeln('• Variação no período: ${peso['variacaoKg']} kg');
      }
      if (peso['kgPorSemana'] != null) {
        buf.writeln('• Ritmo: ${peso['kgPorSemana']} kg/semana');
      }
      if (peso['imc'] != null) {
        buf.writeln('• IMC atual: ${peso['imc']} (${peso['classeOms']})');
      }
    }
    if (dose['adesaoPct'] != null) {
      buf.writeln(
          '• Doses aplicadas: ${dose['aplicadas']}/${dose['esperadas']} (${dose['adesaoPct']}%)');
    }
    if (top.isNotEmpty) {
      buf.writeln('• Sintomas mais frequentes:');
      for (final s in top.take(3)) {
        buf.writeln(
            '   - ${s['nome']} · ${s['ocorrencias']}× (dominante: ${s['intensidadeDominante'] ?? '—'})');
      }
    }
    buf
      ..writeln()
      ..writeln('*Perguntas para levar ao médico:*');
    var i = 1;
    for (final p in perguntas) {
      buf.writeln('$i. ${p['texto']}');
      if (p['referencia'] != null) {
        buf.writeln('   Fonte: ${p['referencia']}');
      }
      i++;
    }
    buf
      ..writeln()
      ..writeln(d['disclaimer'] ?? '');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar consulta')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _construirCorpo(),
      ),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return ListView(
        padding: const EdgeInsets.all(RecorpoSpacing.lg),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_erro!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ),
        ],
      );
    }
    final d = _dados;
    if (d == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final fatos = d['fatos'] as Map<String, dynamic>;
    final perguntas = (d['perguntas'] as List).cast<Map<String, dynamic>>();
    final disclaimer = d['disclaimer'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(RecorpoSpacing.lg),
      children: [
        // Disclaimer topo
        _Disclaimer(texto: disclaimer),
        const SizedBox(height: RecorpoSpacing.lg),

        Text('Seus fatos',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        const SizedBox(height: 4),
        Text(
          'Compilados dos últimos ${fatos['janelaDias']} dias dos seus registros.',
          style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: RecorpoSpacing.md),
        _FatosGrid(fatos: fatos),

        const SizedBox(height: RecorpoSpacing.xl),
        Text('Sintomas mais frequentes',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        const SizedBox(height: RecorpoSpacing.sm),
        _ListaSintomas(topSintomas:
            (fatos['topSintomas'] as List).cast<Map<String, dynamic>>()),

        const SizedBox(height: RecorpoSpacing.xl),
        Text('Perguntas para o seu médico',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        const SizedBox(height: 4),
        Text(
          'Selecionadas a partir dos seus dados e revisadas em bulas e diretrizes públicas.',
          style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: RecorpoSpacing.md),
        if (perguntas.isEmpty)
          Text('Nenhuma pergunta gerada — registre mais dias e volte aqui.',
              style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6)))
        else
          ...perguntas.asMap().entries.map(
                (e) => _CardPergunta(indice: e.key + 1, pergunta: e.value),
              ),

        const SizedBox(height: RecorpoSpacing.xl),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _copiarParaCompartilhar,
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copiar resumo'),
          ),
        ),
        const SizedBox(height: RecorpoSpacing.md),
        _Disclaimer(texto: disclaimer, compacto: true),
        const SizedBox(height: RecorpoSpacing.xl),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final String texto;
  final bool compacto;
  const _Disclaimer({required this.texto, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: RecorpoColors.alertaClinico.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
        border: Border.all(
          color: RecorpoColors.alertaClinico.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: RecorpoColors.alertaClinico,
              size: compacto ? 16 : 20),
          const SizedBox(width: RecorpoSpacing.sm),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: compacto ? 11 : 12.5,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FatosGrid extends StatelessWidget {
  final Map<String, dynamic> fatos;
  const _FatosGrid({required this.fatos});

  @override
  Widget build(BuildContext context) {
    final peso = fatos['peso'] as Map<String, dynamic>;
    final dose = fatos['dose'] as Map<String, dynamic>;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Cartao(
                rotulo: 'Peso atual',
                valor: peso['atual'] == null
                    ? '—'
                    : '${peso['atual']} kg',
                sub: peso['variacaoKg'] == null
                    ? 'Sem histórico'
                    : peso['variacaoKg'] < 0
                        ? '${peso['variacaoKg']} kg no período'
                        : '+${peso['variacaoKg']} kg no período',
                eixo: EixoRecorpo.peso,
              ),
            ),
            const SizedBox(width: RecorpoSpacing.sm),
            Expanded(
              child: _Cartao(
                rotulo: 'Ritmo',
                valor: peso['kgPorSemana'] == null
                    ? '—'
                    : '${peso['kgPorSemana']}',
                sub: peso['kgPorSemana'] == null
                    ? 'Precisa 14+ dias'
                    : 'kg por semana',
                eixo: EixoRecorpo.peso,
              ),
            ),
          ],
        ),
        const SizedBox(height: RecorpoSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Cartao(
                rotulo: 'IMC',
                valor: peso['imc'] == null
                    ? '—'
                    : '${peso['imc']}',
                sub: peso['classeOms'] ?? 'Sem altura no perfil',
                eixo: EixoRecorpo.peso,
              ),
            ),
            const SizedBox(width: RecorpoSpacing.sm),
            Expanded(
              child: _Cartao(
                rotulo: 'Adesão',
                valor: dose['adesaoPct'] == null
                    ? '—'
                    : '${dose['adesaoPct']}%',
                sub:
                    '${dose['aplicadas']} de ${dose['esperadas']} doses',
                eixo: EixoRecorpo.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  final String rotulo;
  final String valor;
  final String sub;
  final EixoRecorpo eixo;
  const _Cartao({
    required this.rotulo,
    required this.valor,
    required this.sub,
    required this.eixo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: RecorpoSpacing.sm),
          Text(valor,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  height: 1)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _ListaSintomas extends StatelessWidget {
  final List<Map<String, dynamic>> topSintomas;
  const _ListaSintomas({required this.topSintomas});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (topSintomas.isEmpty) {
      return Text('Nenhum sintoma registrado no período.',
          style:
              TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)));
    }
    return Column(
      children: topSintomas.take(5).map((s) {
        final intensa = (s['intensidadeDominante'] as String?)?.toLowerCase() ==
            'intensa';
        return Padding(
          padding: const EdgeInsets.only(bottom: RecorpoSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: RecorpoSpacing.md,
                vertical: RecorpoSpacing.md),
            decoration: BoxDecoration(
              color: intensa
                  ? RecorpoColors.eixoSintomas.withValues(alpha: 0.10)
                  : scheme.surface,
              borderRadius:
                  BorderRadius.circular(RecorpoSpacing.radiusSm),
              border: Border.all(
                color: intensa
                    ? RecorpoColors.eixoSintomas.withValues(alpha: 0.4)
                    : scheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['nome'] as String,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        'Dominante: ${s['intensidadeDominante'] ?? '—'}',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                scheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s['ocorrencias']}×',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CardPergunta extends StatelessWidget {
  final int indice;
  final Map<String, dynamic> pergunta;
  const _CardPergunta({required this.indice, required this.pergunta});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ref = pergunta['referencia'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: RecorpoSpacing.sm),
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: RecorpoGradients.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$indice',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: RecorpoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pergunta['texto'] as String,
                  style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: scheme.onSurface),
                ),
                if (ref != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 12,
                          color:
                              scheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text('Fonte: $ref',
                          style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.55))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
