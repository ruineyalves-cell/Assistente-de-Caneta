/**
 * Lote 32.2 — Pré-consulta determinística (sem IA).
 *
 * Módulo puro que a partir de uma lista de daily_logs (já
 * descriptografada) + perfil do paciente produz um objeto de fatos
 * objetivos que o paciente pode levar ao médico. Zero interpretação
 * clínica, zero prescrição, zero prognóstico.
 *
 * As perguntas sugeridas ao médico são calculadas em
 * `perguntasPreConsulta.js` a partir destes fatos.
 */

'use strict';

/**
 * Semanas cheias de dados no período. Serve pra calcular kg/semana
 * sem enviesar por semana parcial.
 */
function diasDePeriodo(logs) {
  if (logs.length === 0) return 0;
  const datas = logs.map((l) => new Date(l.data));
  const min = new Date(Math.min(...datas));
  const max = new Date(Math.max(...datas));
  return Math.floor((max - min) / 86_400_000) + 1;
}

function logsComPeso(logs) {
  return logs
    .filter((l) => l.pesoKg != null)
    .sort((a, b) => new Date(a.data) - new Date(b.data));
}

function parseSintomas(efeitos) {
  if (!efeitos) return [];
  try {
    const j = JSON.parse(efeitos);
    if (j && Array.isArray(j.sintomas)) {
      return j.sintomas.filter((s) => s && s.nome);
    }
  } catch {
    /* efeitos não é JSON válido — ignora */
  }
  return [];
}

/**
 * Agrega ocorrências de sintomas em todo o período e ordena por
 * frequência (mais frequente primeiro). Intensidade agregada é a
 * MODA (a que aparece mais vezes) — se empatar, "intensa" tem
 * precedência para o paciente conversar com o médico.
 */
function agregarSintomas(logs) {
  const contador = new Map();
  for (const l of logs) {
    const sintomas = parseSintomas(l.efeitos);
    for (const s of sintomas) {
      const chave = String(s.nome).trim().toLowerCase();
      if (!contador.has(chave)) {
        contador.set(chave, { nome: s.nome, ocorrencias: 0, intensidades: [] });
      }
      const c = contador.get(chave);
      c.ocorrencias += 1;
      if (s.intensidade) c.intensidades.push(String(s.intensidade).toLowerCase());
    }
  }

  const ordem = ['intensa', 'moderada', 'leve'];
  const resultado = [];
  for (const s of contador.values()) {
    const freq = {};
    for (const i of s.intensidades) freq[i] = (freq[i] || 0) + 1;
    let intensidadeDominante = null;
    let maxFreq = 0;
    for (const nivel of ordem) {
      const f = freq[nivel] || 0;
      if (f > maxFreq) {
        maxFreq = f;
        intensidadeDominante = nivel;
      }
    }
    resultado.push({
      nome: s.nome,
      ocorrencias: s.ocorrencias,
      intensidadeDominante,
    });
  }
  resultado.sort((a, b) => b.ocorrencias - a.ocorrencias);
  return resultado;
}

/**
 * Calcula IMC + classe OMS. Retorna null se altura desconhecida.
 * Referência: OMS. Faixas usadas SÓ como classificação estatística;
 * não representam diagnóstico clínico (isso é obrigação do médico).
 */
function classificarImc(pesoKg, alturaCm) {
  if (pesoKg == null || alturaCm == null || alturaCm <= 0) return null;
  const alturaM = alturaCm / 100;
  const imc = pesoKg / (alturaM * alturaM);
  let classe;
  if (imc < 18.5) classe = 'baixo peso';
  else if (imc < 25) classe = 'eutrofia';
  else if (imc < 30) classe = 'sobrepeso';
  else if (imc < 35) classe = 'obesidade grau I';
  else if (imc < 40) classe = 'obesidade grau II';
  else classe = 'obesidade grau III';
  return { imc: Number(imc.toFixed(1)), classe };
}

/**
 * Calcula todos os fatos objetivos que a pré-consulta apresenta ao
 * paciente. `logs` deve estar descriptografado e cobrir os últimos
 * ~30-60 dias (o próprio controller decide o corte).
 */
function calcularFatos({ perfil, logs, janelaDias = 30 }) {
  const totalDias = janelaDias;
  const registros = logs.length;
  const adesaoRegistro = registros === 0 ? 0 : Math.min(1, registros / totalDias);

  const comPeso = logsComPeso(logs);
  const pesoInicial = comPeso.length > 0 ? comPeso[0].pesoKg : null;
  const pesoAtual = comPeso.length > 0 ? comPeso[comPeso.length - 1].pesoKg : null;
  const variacaoKg = pesoInicial != null && pesoAtual != null
    ? Number((pesoAtual - pesoInicial).toFixed(1))
    : null;

  // Kg por semana só faz sentido se temos pelo menos 2 semanas
  // amostradas — abaixo disso é ruído.
  let kgPorSemana = null;
  if (variacaoKg != null && comPeso.length >= 2) {
    const diasEntre = diasDePeriodo(comPeso);
    if (diasEntre >= 14) {
      kgPorSemana = Number((variacaoKg / (diasEntre / 7)).toFixed(2));
    }
  }

  const dosesAplicadas = logs.filter((l) => l.doseAplicada === true).length;
  // GLP-1 típico é semanal — em 30 dias esperamos 4 doses.
  const dosesEsperadas = Math.max(1, Math.round(janelaDias / 7));
  const adesaoDose = dosesEsperadas === 0
    ? null
    : Math.min(1, dosesAplicadas / dosesEsperadas);

  const sintomas = agregarSintomas(logs);
  const topSintomas = sintomas.slice(0, 5);

  const imc = classificarImc(pesoAtual, perfil?.alturaCm);

  return {
    janelaDias,
    registros,
    adesaoRegistroPct: Math.round(adesaoRegistro * 100),
    peso: {
      inicial: pesoInicial,
      atual: pesoAtual,
      variacaoKg,
      kgPorSemana,
      imc: imc?.imc ?? null,
      classeOms: imc?.classe ?? null,
    },
    dose: {
      aplicadas: dosesAplicadas,
      esperadas: dosesEsperadas,
      adesaoPct: adesaoDose == null ? null : Math.round(adesaoDose * 100),
    },
    topSintomas,
    medicacao: perfil?.medicacao?.nome ?? null,
  };
}

module.exports = { calcularFatos, agregarSintomas, classificarImc };
