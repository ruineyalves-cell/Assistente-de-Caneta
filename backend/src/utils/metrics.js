/**
 * MOTOR DE MÉTRICAS DE CONFORMIDADE — 100% determinístico, sem IA.
 *
 * Regra regulatória (juridico/CONFORMIDADE_ANVISA.md):
 *  - Nenhuma saída orienta conduta clínica.
 *  - Todo alerta cita FONTE PÚBLICA e termina remetendo ao médico.
 *  - O score mede aderência ao PLANO DE REGISTRO, não estado clínico.
 *
 * Metas padrão (diretrizes públicas gerais, ajustáveis pelo profissional):
 *  - Proteína: 1.2 g/kg/dia (ABESO — preservação de massa magra em uso de GLP-1)
 *  - Hidratação: 35 ml/kg/dia (diretriz geral de hidratação)
 */

const PESOS = { proteina: 0.4, hidratacao: 0.3, registro: 0.3 };

/**
 * @param {object} p
 * @param {number|null} p.pesoKg         peso registrado no dia (ou último conhecido)
 * @param {number|null} p.proteinaG      proteína consumida no dia (g)
 * @param {number|null} p.aguaMl         água consumida no dia (ml)
 * @param {boolean}     p.registrou      houve registro no dia
 * @param {number}      [p.metaProteinaGkg=1.2]
 * @param {number}      [p.metaAguaMlKg=35]
 * @returns {{score:number, componentes:object, alertas:Array}}
 */
function calcularConformidadeDia(p) {
  const metaProteinaGkg = p.metaProteinaGkg ?? 1.2;
  const metaAguaMlKg = p.metaAguaMlKg ?? 35;
  const alertas = [];

  // --- componente: registro do dia ---
  const registro = p.registrou ? 100 : 0;
  if (!p.registrou) {
    alertas.push(alerta('SEM_REGISTRO',
      'Você não registrou dados hoje. Registros consistentes ajudam seu médico a acompanhar seu tratamento.',
      'Boas práticas de automonitoramento (ADA Standards of Care)'));
  }

  // --- componente: proteína ---
  let proteina = null;
  if (p.pesoKg && p.proteinaG !== null && p.proteinaG !== undefined) {
    const metaG = p.pesoKg * metaProteinaGkg;
    proteina = clamp(Math.round((p.proteinaG / metaG) * 100), 0, 100);
    if (proteina < 80) {
      alertas.push(alerta('PROTEINA_BAIXA',
        `Diretrizes públicas (ABESO) citam ~${metaProteinaGkg} g de proteína por kg de peso ao dia para preservar massa magra durante tratamentos de perda de peso. Seu registro de hoje indica ${p.proteinaG} g (meta de referência: ${Math.round(metaG)} g). Converse com seu médico ou nutricionista sobre a meta ideal para você.`,
        'ABESO — Diretrizes Brasileiras de Obesidade'));
    }
  }

  // --- componente: hidratação ---
  let hidratacao = null;
  if (p.pesoKg && p.aguaMl !== null && p.aguaMl !== undefined) {
    const metaMl = p.pesoKg * metaAguaMlKg;
    hidratacao = clamp(Math.round((p.aguaMl / metaMl) * 100), 0, 100);
    if (hidratacao < 70) {
      alertas.push(alerta('HIDRATACAO_BAIXA',
        `Bulas de agonistas GLP-1 alertam que náusea/vômito podem causar desidratação; diretrizes gerais citam ~${metaAguaMlKg} ml/kg/dia. Seu registro indica ${p.aguaMl} ml (referência: ${Math.round(metaMl)} ml). Converse com seu médico sobre sua hidratação.`,
        'Bula (Anvisa) — seção Advertências e Precauções'));
    }
  }

  // --- score ponderado (componentes sem dado não penalizam, redistribuem peso) ---
  const partes = [];
  if (proteina !== null) partes.push([proteina, PESOS.proteina]);
  if (hidratacao !== null) partes.push([hidratacao, PESOS.hidratacao]);
  partes.push([registro, PESOS.registro]);

  const somaPesos = partes.reduce((s, [, w]) => s + w, 0);
  const score = Math.round(partes.reduce((s, [v, w]) => s + v * w, 0) / somaPesos);

  return {
    score: clamp(score, 0, 100),
    componentes: { proteina, hidratacao, registro },
    alertas,
  };
}

/**
 * Streak de registros: dias consecutivos (terminando na data mais recente) com log.
 * @param {string[]} datasComLog datas 'YYYY-MM-DD' ordenadas ou não
 * @param {string} hoje 'YYYY-MM-DD'
 */
function calcularStreak(datasComLog, hoje) {
  const set = new Set(datasComLog);
  let streak = 0;
  let d = new Date(`${hoje}T00:00:00Z`);
  // streak conta a partir de hoje OU de ontem (dia corrente ainda em aberto)
  if (!set.has(isoDate(d))) d.setUTCDate(d.getUTCDate() - 1);
  while (set.has(isoDate(d))) {
    streak += 1;
    d.setUTCDate(d.getUTCDate() - 1);
  }
  return streak;
}

function alerta(codigo, mensagem, fonte) {
  return {
    codigo,
    mensagem,
    fonte,
    rodape: 'Alerta educativo. Não é recomendação médica. Consulte sempre seu médico.',
  };
}

function clamp(n, min, max) { return Math.min(max, Math.max(min, n)); }
function isoDate(d) { return d.toISOString().slice(0, 10); }

module.exports = { calcularConformidadeDia, calcularStreak, PESOS };
