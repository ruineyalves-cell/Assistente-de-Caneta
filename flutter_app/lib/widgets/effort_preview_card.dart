import 'package:flutter/material.dart';

import '../models/patient_profile.dart';
import '../services/effort_advisor.dart';
import '../utils/constants.dart';

/// Card de prévia do Ajuste de Esforço no dashboard.
///
/// Mostra uma linha por modalidade (corrida/ciclismo) com a intensidade
/// recomendada, e um botão "Ver detalhes" que abre a EffortScreen com a
/// justificativa e o disclaimer completos.
class EffortPreviewCard extends StatelessWidget {
  final EixoFarmacologico? eixo;
  final VoidCallback onAbrir;

  const EffortPreviewCard({
    super.key,
    required this.eixo,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    const advisor = EffortAdvisor();
    final recs = advisor.recomendacoes(eixo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_run,
                    color: AppColors.azulClinico, size: 20),
                const SizedBox(width: 8),
                Text('Ajuste de esforço',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...recs.map(_linhaPreview),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAbrir,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver detalhes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaPreview(RecomendacaoEsforco r) {
    final cor = _corIntensidade(r.intensidade);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(r.modalidade.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(r.modalidade.label,
                style: const TextStyle(fontSize: 13)),
          ),
          Text(r.intensidade.label,
              style: TextStyle(
                  fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('${r.duracaoMinutos} min · ${r.frequenciaSemanal}×/sem',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _corIntensidade(IntensidadeAerobica i) {
    switch (i) {
      case IntensidadeAerobica.leve:
        return AppColors.verdeConfirma;
      case IntensidadeAerobica.moderada:
        return AppColors.azulClinico;
      case IntensidadeAerobica.vigorosa:
        return AppColors.vermelhoAlerta;
    }
  }
}
