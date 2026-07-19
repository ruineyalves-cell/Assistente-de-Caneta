/**
 * Lote 32.3 — Resumo diário determinístico.
 *
 * Substitui a "dica genérica" antiga do dashboard por um texto real
 * dos registros do próprio usuário. Zero IA. Cada linha é um FATO
 * observado — nunca conduta, nunca prescrição.
 *
 * Formato de saída:
 *   {
 *     saudacao: 'manha' | 'tarde' | 'noite',
 *     dataRef:  'YYYY-MM-DD',
 *     linhas: [{ tipo, texto }],
 *     vazio:  bool,
 *   }
 *
 * `tipo` ajuda o cliente a colorir cada linha (usamos as cores dos
 * eixos do app: refeicao/agua/peso/dose/sintomas/dica).
 */

'use strict';

function faixaHoraria(agora = new Date()) {
  const h = agora.getHours();
  if (h < 5) return 'noite';
  if (h < 12) return 'manha';
  if (h < 18) return 'tarde';
  return 'noite';
}

function parseSintomas(efeitos) {
  if (!efeitos) return [];
  try {
    const j = JSON.parse(efeitos);
    if (j && Array.isArray(j.sintomas)) {
      return j.sintomas.filter((s) => s && s.nome);
    }
  } catch {
    /* ignora */
  }
  return [];
}

/**
 * Formata litros a partir de ml. Aceita null.
 *   1800 → "1,8 L"
 *   null → null
 */
function litros(ml) {
  if (ml == null) return null;
  const L = ml / 1000;
  return `${L.toFixed(1).replace('.', ',')} L`;
}

/**
 * Monta o resumo. Recebe:
 *   - perfil: retorno de patientModel.perfil (pode ser null)
 *   - logHoje: log daily do dia atual (pode ser null se nada registrado)
 *   - logsRecentes: últimos 7 dias (usado só para média de sintomas)
 *   - agora: Date (útil para testes)
 */
function calcularResumo({ perfil, logHoje, logsRecentes = [], agora = new Date() }) {
  const dataRef = agora.toISOString().slice(0, 10);
  const linhas = [];

  const pesoInicial = perfil?.pesoInicialKg ?? null;
  const metaAguaMlKg = perfil?.metaAguaMlKg ?? 35;
  const metaAguaMl = pesoInicial != null ? Math.round(pesoInicial * metaAguaMlKg) : null;

  const proteinaAlvoGkg = perfil?.metaProteinaGkg ?? 1.2;
  const metaProteinaG = pesoInicial != null ? Math.round(pesoInicial * proteinaAlvoGkg) : null;

  // ─── Refeições ──────────────────────────────────────────────
  const alimentos = logHoje?.alimentos ?? '';
  // "Peso: 87.2 kg @ Casa" também entra no campo alimentos (Lote 32);
  // filtramos linhas que começam com "Peso:" para não contar como
  // refeição.
  const refeicoesLinhas = alimentos
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l && !/^peso\s*:/i.test(l));
  const nRefeicoes = refeicoesLinhas.length;
  if (nRefeicoes === 1) {
    linhas.push({ tipo: 'refeicao', texto: 'Você já registrou 1 refeição hoje.' });
  } else if (nRefeicoes > 1) {
    linhas.push({
      tipo: 'refeicao',
      texto: `Você já registrou ${nRefeicoes} refeições hoje.`,
    });
  }

  // ─── Proteína (só menciona se houve registro) ───────────────
  const proteinaG = logHoje?.proteinaG ?? null;
  if (proteinaG != null && metaProteinaG != null && metaProteinaG > 0) {
    if (proteinaG >= metaProteinaG) {
      linhas.push({
        tipo: 'refeicao',
        texto: `Meta de proteína batida: ${proteinaG} g (alvo ${metaProteinaG} g).`,
      });
    } else {
      const falta = metaProteinaG - proteinaG;
      linhas.push({
        tipo: 'refeicao',
        texto: `Faltam ${falta} g para bater a meta de proteína (${proteinaG}/${metaProteinaG} g).`,
      });
    }
  }

  // ─── Água ───────────────────────────────────────────────────
  const aguaMl = logHoje?.aguaMl ?? 0;
  if (aguaMl > 0 || metaAguaMl != null) {
    if (metaAguaMl == null) {
      linhas.push({ tipo: 'agua', texto: `Hidratação de hoje: ${litros(aguaMl)}.` });
    } else if (aguaMl >= metaAguaMl) {
      linhas.push({
        tipo: 'agua',
        texto: `Meta de hidratação batida: ${litros(aguaMl)} de ${litros(metaAguaMl)}.`,
      });
    } else {
      const faltamMl = metaAguaMl - aguaMl;
      linhas.push({
        tipo: 'agua',
        texto: `Faltam ${litros(faltamMl)} para bater a meta de hidratação (${litros(aguaMl)} de ${litros(metaAguaMl)}).`,
      });
    }
  }

  // ─── Peso ───────────────────────────────────────────────────
  if (logHoje?.pesoKg != null) {
    linhas.push({
      tipo: 'peso',
      texto: `Peso registrado hoje: ${logHoje.pesoKg.toFixed(1).replace('.', ',')} kg.`,
    });
  }

  // ─── Dose semanal ───────────────────────────────────────────
  if (logHoje?.doseAplicada === true) {
    linhas.push({ tipo: 'dose', texto: 'Dose aplicada hoje.' });
  }

  // ─── Sintomas ───────────────────────────────────────────────
  const sintomasHoje = parseSintomas(logHoje?.efeitos);
  if (sintomasHoje.length > 0) {
    // Se tem "intensa", destaca o primeiro intenso; caso contrário,
    // resume por contagem.
    const intenso = sintomasHoje.find(
      (s) => String(s.intensidade).toLowerCase() === 'intensa',
    );
    if (intenso) {
      linhas.push({
        tipo: 'sintomas',
        texto: `Sintoma intenso registrado hoje: ${intenso.nome}.`,
      });
    } else if (sintomasHoje.length === 1) {
      linhas.push({
        tipo: 'sintomas',
        texto: `1 sintoma registrado hoje: ${sintomasHoje[0].nome}.`,
      });
    } else {
      linhas.push({
        tipo: 'sintomas',
        texto: `${sintomasHoje.length} sintomas registrados hoje.`,
      });
    }
  }

  // ─── Nada registrado ainda ─────────────────────────────────
  const vazio = linhas.length === 0;
  if (vazio) {
    linhas.push({
      tipo: 'dica',
      texto:
        'Hoje ainda sem registros. Cada eixo aceita um toque rápido — refeição, água, peso ou sintomas.',
    });
  }

  return {
    saudacao: faixaHoraria(agora),
    dataRef,
    vazio,
    linhas,
  };
}

module.exports = { calcularResumo, faixaHoraria };
