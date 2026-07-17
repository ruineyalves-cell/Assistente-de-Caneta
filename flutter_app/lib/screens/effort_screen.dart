import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile.dart';
import '../services/effort_advisor.dart';
import '../utils/constants.dart';

/// Tela do Ajuste de Esforço (Lote 12).
///
/// Mostra recomendação educacional de intensidade / duração / frequência
/// para corrida e ciclismo, tomando o eixo farmacológico do perfil como
/// pivô. Toda a lógica está em [EffortAdvisor] — a tela é apresentação.
class EffortScreen extends StatefulWidget {
  const EffortScreen({super.key});

  @override
  State<EffortScreen> createState() => _EffortScreenState();
}

class _EffortScreenState extends State<EffortScreen> {
  final _advisor = const EffortAdvisor();
  EixoFarmacologico? _eixo;
  bool _carregado = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(ProfilePrefsKeys.eixoFarmacologico);
    if (!mounted) return;
    setState(() {
      _eixo = nome == null
          ? null
          : EixoFarmacologico.values
              .cast<EixoFarmacologico?>()
              .firstWhere((v) => v?.name == nome, orElse: () => null);
      _carregado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuste de esforço')),
      body: !_carregado
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CabecalhoEixo(eixo: _eixo),
                  const SizedBox(height: 16),
                  ..._advisor
                      .recomendacoes(_eixo)
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecomendacaoCard(rec: r),
                          )),
                  const SizedBox(height: 8),
                  const _DisclaimerEducacional(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _CabecalhoEixo extends StatelessWidget {
  final EixoFarmacologico? eixo;
  const _CabecalhoEixo({required this.eixo});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.azulClinico.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.azulClinico.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.science_outlined,
                color: AppColors.azulClinico),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EIXO ATUAL',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: AppColors.azulClinico,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    eixo?.label ?? 'Não configurado',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecomendacaoCard extends StatelessWidget {
  final RecomendacaoEsforco rec;
  const _RecomendacaoCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(rec.modalidade.emoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(rec.modalidade.label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                _ChipIntensidade(intensidade: rec.intensidade),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                      icone: Icons.timer_outlined,
                      valor: '${rec.duracaoMinutos} min',
                      rotulo: 'Duração'),
                ),
                Expanded(
                  child: _Kpi(
                      icone: Icons.event_repeat_outlined,
                      valor: '${rec.frequenciaSemanal}×/semana',
                      rotulo: 'Frequência'),
                ),
                Expanded(
                  child: _Kpi(
                      icone: Icons.record_voice_over_outlined,
                      valor: rec.intensidade.descricao,
                      rotulo: 'Percepção',
                      valorFontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rec.justificativa,
                      style: const TextStyle(
                          fontSize: 12, height: 1.4, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipIntensidade extends StatelessWidget {
  final IntensidadeAerobica intensidade;
  const _ChipIntensidade({required this.intensidade});

  Color get _cor {
    switch (intensidade) {
      case IntensidadeAerobica.leve:
        return AppColors.verdeConfirma;
      case IntensidadeAerobica.moderada:
        return AppColors.azulClinico;
      case IntensidadeAerobica.vigorosa:
        return AppColors.vermelhoAlerta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cor.withValues(alpha: 0.4)),
      ),
      child: Text(intensidade.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _cor)),
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String rotulo;
  final double valorFontSize;
  const _Kpi({
    required this.icone,
    required this.valor,
    required this.rotulo,
    this.valorFontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, size: 18, color: AppColors.azulClinico),
        const SizedBox(height: 4),
        Text(valor,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: valorFontSize, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(rotulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _DisclaimerEducacional extends StatelessWidget {
  const _DisclaimerEducacional();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.vermelhoAlerta.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.vermelhoAlerta.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 18, color: AppColors.vermelhoAlerta),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Estas recomendações são educativas — não substituem '
              'a orientação do seu médico ou educador físico. Ajuste '
              'à sua condição, presença de outras doenças e '
              'sintomas do dia.',
              style: TextStyle(fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
