/**
 * Lote 32.4 — Detector de alertas clínicos objetivos.
 *
 * Todos os alertas seguem a mesma linha jurídica da pré-consulta
 * (Lote 32.2): apenas fatos + convite ao diálogo médico. Nunca
 * "diagnóstico", nunca "prescrição", nunca "prognóstico".
 *
 * Formato do alerta retornado:
 *   {
 *     tipo: 'sintoma-persistente' | ...,
 *     severidade: 'atencao' | 'importante',
 *     titulo: string curto,
 *     descricao: string com o dado objetivo,
 *     cta: string com a ação sugerida (nunca conduta clínica),
 *     dados: { … metadata específica do tipo … },
 *   }
 */

'use strict';

function parseSintomas(efeitos) {
  if (!efeitos) return [];
  try {
    const j = JSON.parse(efeitos);
    if (j && Array.isArray(j.sintomas)) {
      return j.sintomas.filter((s) => s && s.nome);
    }
  } catch {
    /* inválido, ignora */
  }
  return [];
}

/**
 * Identifica sintomas registrados como INTENSOS em ≥ `diasMinimos`
 * dias distintos dentro dos últimos `janelaDias` dias.
 *
 * `janelaDias=7, diasMinimos=3` é a regra que combinamos com o usuário:
 * pega padrão persistente sem gerar ruído por dia isolado ruim.
 *
 * Retorna array (possivelmente vazio) ordenado do mais frequente ao
 * menos frequente.
 */
function detectarSintomasPersistentes(logs, { janelaDias = 7, diasMinimos = 3 } = {}) {
  const agora = new Date();
  const corte = new Date(agora.getTime() - janelaDias * 86_400_000);

  // Chave: sintoma normalizado → Set de datas (YYYY-MM-DD) em que
  // apareceu como intenso. Set evita contar dobrado se o usuário
  // registrou o mesmo sintoma duas vezes no mesmo dia.
  const diasIntensos = new Map();
  const nomeOriginal = new Map();

  for (const l of logs) {
    const data = new Date(l.data);
    if (data < corte) continue;
    const chaveDia = data.toISOString().slice(0, 10);
    for (const s of parseSintomas(l.efeitos)) {
      if (String(s.intensidade).toLowerCase() !== 'intensa') continue;
      const chave = String(s.nome).trim().toLowerCase();
      if (!diasIntensos.has(chave)) {
        diasIntensos.set(chave, new Set());
        nomeOriginal.set(chave, s.nome);
      }
      diasIntensos.get(chave).add(chaveDia);
    }
  }

  const resultado = [];
  for (const [chave, dias] of diasIntensos.entries()) {
    if (dias.size >= diasMinimos) {
      resultado.push({
        nome: nomeOriginal.get(chave),
        diasIntensos: dias.size,
        janelaDias,
      });
    }
  }
  resultado.sort((a, b) => b.diasIntensos - a.diasIntensos);
  return resultado;
}

/**
 * Combina os detectores em uma lista única de alertas.
 * Por enquanto só temos sintoma-persistente; a arquitetura já deixa
 * pronto para adicionar outros (ganho de peso rápido, etc.).
 */
function calcularAlertas(logs) {
  const alertas = [];

  const persistentes = detectarSintomasPersistentes(logs);
  for (const s of persistentes) {
    alertas.push({
      tipo: 'sintoma-persistente',
      severidade: 'importante',
      titulo: `"${s.nome}" intenso há vários dias`,
      descricao:
        `Você registrou "${s.nome}" com intensidade intensa em ` +
        `${s.diasIntensos} dias dos últimos ${s.janelaDias}. ` +
        `Pode fazer sentido conversar com quem prescreveu.`,
      cta: 'Ver detalhes na pré-consulta',
      dados: {
        sintoma: s.nome,
        diasIntensos: s.diasIntensos,
        janelaDias: s.janelaDias,
      },
    });
  }

  return alertas;
}

module.exports = { detectarSintomasPersistentes, calcularAlertas };
