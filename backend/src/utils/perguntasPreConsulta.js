/**
 * Lote 32.2 — Pool de perguntas curadas para pré-consulta.
 *
 * Cada pergunta é um TEMPLATE textual pré-aprovado (revisado para não
 * fazer prescrição/diagnóstico). Nenhuma frase é gerada por IA — a
 * seleção é 100% baseada em regras determinísticas sobre os fatos
 * calculados em `preConsulta.js`.
 *
 * Por que essa arquitetura mata risco jurídico:
 *  - A pergunta NÃO orienta conduta ("reduza a dose", "pare X").
 *  - A pergunta CONVIDA à conversa médica ("como conversar", "faz
 *    sentido revisar").
 *  - Toda referência é a bula/diretriz pública com atribuição.
 *  - Se nenhuma regra dispara, mostramos perguntas neutras (base).
 *
 * Fontes referenciadas: bulas Anvisa dos análogos GLP-1 (semaglutida,
 * tirzepatida, liraglutida), ABESO 2023 e ADA 2024. Nunca citamos
 * "estudo mostra que…" — só o que está publicamente na bula.
 */

'use strict';

const CATEGORIAS = {
  SINTOMAS: 'sintomas',
  PESO: 'peso',
  DOSE: 'dose',
  ADESAO: 'adesao',
  BASE: 'base',
};

const REFS = {
  BULA_ANVISA: 'Bula Anvisa',
  ABESO: 'ABESO 2023',
  ADA: 'ADA 2024',
  OMS: 'OMS',
};

/**
 * Pool completo. Cada item tem `gatilho(f)` que recebe os fatos
 * (retorno de calcularFatos) e diz se a pergunta é relevante.
 * Sempre revisar textos aqui em vez de gerar por IA.
 */
const POOL = [
  // ─── SINTOMAS PERSISTENTES ────────────────────────────────────
  {
    id: 'sintoma-intenso-persistente',
    categoria: CATEGORIAS.SINTOMAS,
    texto: (f) => {
      const s = f.topSintomas.find(
        (x) => x.intensidadeDominante === 'intensa' && x.ocorrencias >= 3,
      );
      if (!s) return null;
      return `Registrei "${s.nome}" intenso em ${s.ocorrencias} dias no último mês. Como devemos abordar esse efeito?`;
    },
    referencia: REFS.BULA_ANVISA,
    gatilho: (f) =>
      f.topSintomas.some(
        (s) => s.intensidadeDominante === 'intensa' && s.ocorrencias >= 3,
      ),
  },
  {
    id: 'sintoma-moderado-frequente',
    categoria: CATEGORIAS.SINTOMAS,
    texto: (f) => {
      const s = f.topSintomas.find(
        (x) =>
          x.intensidadeDominante === 'moderada' && x.ocorrencias >= 8,
      );
      if (!s) return null;
      return `"${s.nome}" apareceu em ${s.ocorrencias} dias com intensidade moderada. Essa frequência é esperada nesta fase?`;
    },
    referencia: REFS.BULA_ANVISA,
    gatilho: (f) =>
      f.topSintomas.some(
        (s) =>
          s.intensidadeDominante === 'moderada' && s.ocorrencias >= 8,
      ),
  },
  {
    id: 'sintomas-multiplos',
    categoria: CATEGORIAS.SINTOMAS,
    texto: () =>
      'Registrei mais de um sintoma no período. Faz sentido conversarmos sobre alguma estratégia de manejo em conjunto?',
    referencia: REFS.BULA_ANVISA,
    gatilho: (f) => f.topSintomas.length >= 3,
  },

  // ─── PESO ─────────────────────────────────────────────────────
  {
    id: 'peso-estagnado',
    categoria: CATEGORIAS.PESO,
    texto: () =>
      'Meu peso está bem estável há algumas semanas. Como interpretamos essa fase do tratamento?',
    referencia: REFS.ABESO,
    gatilho: (f) =>
      f.peso.variacaoKg != null &&
      Math.abs(f.peso.variacaoKg) < 0.5 &&
      f.registros >= 14,
  },
  {
    id: 'peso-ganho',
    categoria: CATEGORIAS.PESO,
    texto: (f) =>
      `Recuperei ${f.peso.variacaoKg.toFixed(1)} kg no período. Quais fatores devemos revisar juntos?`,
    referencia: REFS.ABESO,
    gatilho: (f) => f.peso.variacaoKg != null && f.peso.variacaoKg >= 1,
  },
  {
    id: 'peso-perda-rapida',
    categoria: CATEGORIAS.PESO,
    texto: (f) =>
      `Perdi ${Math.abs(f.peso.variacaoKg).toFixed(1)} kg no mês (${f.peso.kgPorSemana} kg/semana). Esse ritmo é seguro para mim?`,
    referencia: REFS.ABESO,
    gatilho: (f) =>
      f.peso.kgPorSemana != null && f.peso.kgPorSemana < -1.0,
  },
  {
    id: 'peso-perda-saudavel',
    categoria: CATEGORIAS.PESO,
    texto: (f) =>
      `Estou perdendo cerca de ${Math.abs(f.peso.kgPorSemana).toFixed(2)} kg por semana. Quando faria sentido revisitar minhas metas?`,
    referencia: REFS.ABESO,
    gatilho: (f) =>
      f.peso.kgPorSemana != null &&
      f.peso.kgPorSemana <= -0.3 &&
      f.peso.kgPorSemana >= -1.0,
  },
  {
    id: 'imc-informativo',
    categoria: CATEGORIAS.PESO,
    texto: (f) =>
      `Meu IMC calculado hoje ficou em ${f.peso.imc} (${f.peso.classeOms} pela OMS). Como isso conversa com o meu plano atual?`,
    referencia: REFS.OMS,
    gatilho: (f) => f.peso.imc != null && f.peso.classeOms != null,
  },

  // ─── DOSE / ADESÃO ────────────────────────────────────────────
  {
    id: 'adesao-dose-baixa',
    categoria: CATEGORIAS.DOSE,
    texto: (f) =>
      `Apliquei ${f.dose.aplicadas} de ${f.dose.esperadas} doses esperadas no período. Como retomamos a regularidade sem sobrecarga?`,
    referencia: REFS.BULA_ANVISA,
    gatilho: (f) =>
      f.dose.adesaoPct != null && f.dose.adesaoPct < 75,
  },
  {
    id: 'adesao-dose-perfeita',
    categoria: CATEGORIAS.DOSE,
    texto: () =>
      'Não perdi doses no período. Faz sentido revisitar dose ou intervalo neste momento?',
    referencia: REFS.BULA_ANVISA,
    gatilho: (f) =>
      f.dose.adesaoPct != null &&
      f.dose.adesaoPct >= 95 &&
      f.dose.aplicadas >= 3,
  },

  // ─── ADESÃO DE REGISTRO ───────────────────────────────────────
  {
    id: 'registro-baixo',
    categoria: CATEGORIAS.ADESAO,
    texto: () =>
      'Não registrei todos os dias no período. Faz diferença para você ter dados diários?',
    referencia: null,
    gatilho: (f) => f.adesaoRegistroPct < 50 && f.registros >= 5,
  },

  // ─── PERGUNTAS-BASE (sempre disponíveis se sobrar espaço) ─────
  {
    id: 'base-plano-alimentar',
    categoria: CATEGORIAS.BASE,
    texto: () =>
      'Tem algum ajuste no plano alimentar que faria diferença nesta fase?',
    referencia: REFS.ABESO,
    gatilho: () => true,
  },
  {
    id: 'base-atividade',
    categoria: CATEGORIAS.BASE,
    texto: () =>
      'Quanto de atividade física seria adequado para o meu momento?',
    referencia: REFS.ABESO,
    gatilho: () => true,
  },
  {
    id: 'base-exames',
    categoria: CATEGORIAS.BASE,
    texto: () =>
      'Faz sentido pedirmos algum exame de acompanhamento agora?',
    referencia: null,
    gatilho: () => true,
  },
];

/**
 * Retorna até `limite` perguntas, priorizando na ordem:
 * sintomas → peso → dose → adesão → base. Nunca repete pergunta.
 */
function selecionarPerguntas(fatos, { limite = 5 } = {}) {
  const ordem = [
    CATEGORIAS.SINTOMAS,
    CATEGORIAS.PESO,
    CATEGORIAS.DOSE,
    CATEGORIAS.ADESAO,
    CATEGORIAS.BASE,
  ];

  const selecionadas = [];
  const jaUsadas = new Set();

  for (const cat of ordem) {
    for (const item of POOL) {
      if (item.categoria !== cat) continue;
      if (jaUsadas.has(item.id)) continue;
      if (selecionadas.length >= limite) break;
      let disparou;
      try {
        disparou = item.gatilho(fatos);
      } catch {
        disparou = false;
      }
      if (!disparou) continue;
      const texto = item.texto(fatos);
      if (!texto) continue;
      jaUsadas.add(item.id);
      selecionadas.push({
        id: item.id,
        categoria: item.categoria,
        texto,
        referencia: item.referencia,
      });
    }
    if (selecionadas.length >= limite) break;
  }

  return selecionadas;
}

module.exports = { selecionarPerguntas, POOL, CATEGORIAS, REFS };
