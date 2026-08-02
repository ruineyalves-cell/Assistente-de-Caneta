/// Motor DETERMINÍSTICO de recomendações educativas do rótulo (Fase 3b).
///
/// ─────────────────────────────────────────────────────────────────────
/// ⚠️ SEGURANÇA / JURÍDICO — mesma linha do `metrics.js` e de `juridico/`:
///  1. A IA só LÊ os números do rótulo. As notas abaixo NÃO são geradas
///     por IA — são conteúdo CURADO, determinístico, de fonte pública.
///  2. Toda nota é EDUCATIVA (fato + fonte), NUNCA prescritiva
///     ("coma isso" / "evite aquilo"). Nunca diagnóstico/prescrição.
///  3. Toda nota remete ao profissional (médico/nutricionista).
///  4. As fontes são as MESMAS já citadas pelo app (ABESO, bula/Anvisa) ou
///     universais (OMS) — não se inventou alegação nova.
///
/// 🔒 PENDENTE REVISÃO CLÍNICA: enquanto `kInsightsRevisadoClinicamente`
///    for false, o painel exibe o selo "em revisão clínica". Antes do
///    launch público, o responsável clínico deve revisar CADA nota e faixa,
///    preencher `kInsightsRevisadoPor` e virar a flag.
/// ─────────────────────────────────────────────────────────────────────
library;

/// Só liberar o painel como "revisado" em produção após assinatura clínica.
const bool kInsightsRevisadoClinicamente = false;

/// Responsável pela revisão clínica (preencher quando assinar).
const String? kInsightsRevisadoPor = null;

class RotuloInsight {
  final String texto;
  final String fonte;

  /// true = ponto de atenção (ícone/cor de cautela);
  /// false = destaque positivo.
  final bool atencao;

  const RotuloInsight({
    required this.texto,
    required this.fonte,
    this.atencao = false,
  });
}

/// Gera as notas educativas a partir dos NÚMEROS do rótulo (por porção).
/// Determinístico: mesmos números → mesmas notas. Faixas conservadoras.
List<RotuloInsight> gerarInsightsRotulo(Map<String, dynamic> dados) {
  double? n(String k) => (dados[k] as num?)?.toDouble();

  final proteina = n('proteinaG');
  final fibra = n('fibraG');
  final sodio = n('sodioMg');
  final satur = n('gordurasSaturadasG');

  final notas = <RotuloInsight>[];

  // Proteína — preservação de massa magra durante perda de peso (GLP-1).
  if (proteina != null && proteina >= 8) {
    notas.add(const RotuloInsight(
      texto: 'Boa fonte de proteína nesta porção — a proteína ajuda a '
          'preservar massa magra durante a perda de peso.',
      fonte: 'ABESO — Diretrizes Brasileiras de Obesidade',
    ));
  }

  // Fibra — saciedade + trânsito intestinal (constipação é comum em GLP-1).
  if (fibra != null && fibra >= 3) {
    notas.add(const RotuloInsight(
      texto: 'Boa fonte de fibra — fibras auxiliam a saciedade e o trânsito '
          'intestinal (constipação é um efeito comum de agonistas GLP-1, '
          'conforme bula).',
      fonte: 'Bula (Anvisa) + diretrizes gerais de fibra',
    ));
  }

  // Sódio alto — OMS + hidratação em GLP-1.
  if (sodio != null && sodio >= 400) {
    notas.add(const RotuloInsight(
      texto: 'Teor de sódio relativamente alto nesta porção. A OMS sugere '
          'até ~2000 mg de sódio por dia; em uso de GLP-1, atenção à '
          'hidratação (a bula alerta risco de desidratação por náusea/'
          'vômito).',
      fonte: 'OMS + Bula (Anvisa)',
      atencao: true,
    ));
  }

  // Gordura saturada alta — moderação (diretriz cardiovascular geral).
  if (satur != null && satur >= 5) {
    notas.add(const RotuloInsight(
      texto: 'Gordura saturada a observar nesta porção — diretrizes gerais '
          'de saúde cardiovascular sugerem moderação.',
      fonte: 'Diretrizes gerais (saúde cardiovascular)',
      atencao: true,
    ));
  }

  return notas;
}
