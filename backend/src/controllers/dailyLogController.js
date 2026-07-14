const { z } = require('zod');
const dailyLogModel = require('../models/dailyLogModel');
const patientModel = require('../models/patientModel');
const { calcularConformidadeDia, calcularStreak } = require('../utils/metrics');

const logSchema = z.object({
  data: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(), // default hoje
  pesoKg: z.number().min(20).max(400).nullable().optional(),
  proteinaG: z.number().min(0).max(1000).nullable().optional(),
  aguaMl: z.number().min(0).max(20000).nullable().optional(),
  alimentos: z.string().max(4000).nullable().optional(),
  doseAplicada: z.boolean().optional(),
  efeitos: z.string().max(4000).nullable().optional(),
});

function hojeISO() { return new Date().toISOString().slice(0, 10); }

/** POST /api/logs — cria/atualiza o log do dia e recalcula conformidade. */
async function registrar(req, res, next) {
  try {
    const d = logSchema.parse(req.body);
    const data = d.data || hojeISO();
    await dailyLogModel.upsert(req.user.id, data, d);

    const resultado = await recalcular(req.user.id, data);
    return res.status(201).json({ data, ...resultado });
  } catch (err) { next(err); }
}

/** Recalcula score do dia com base no log + perfil. */
async function recalcular(patientId, data) {
  const [log, perfil] = await Promise.all([
    dailyLogModel.porData(patientId, data),
    patientModel.perfil(patientId),
  ]);
  const pesoKg = log?.pesoKg ?? (await dailyLogModel.ultimoPeso(patientId));

  const resultado = calcularConformidadeDia({
    pesoKg,
    proteinaG: log?.proteinaG ?? null,
    aguaMl: log?.aguaMl ?? null,
    registrou: !!log,
    metaProteinaGkg: perfil?.metaProteinaGkg,
    metaAguaMlKg: perfil?.metaAguaMlKg,
  });
  await dailyLogModel.salvarScore(patientId, data, resultado);
  return resultado;
}

/** GET /api/logs?desde=&ate= */
async function listar(req, res, next) {
  try {
    const q = z.object({
      desde: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
      ate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    }).parse(req.query);
    const logs = await dailyLogModel.listar(req.user.id, q);
    return res.json({ logs });
  } catch (err) { next(err); }
}

/** GET /api/logs/dashboard — cards + streak + últimos scores. */
async function dashboard(req, res, next) {
  try {
    const patientId = req.user.id;
    const hoje = hojeISO();
    const [logHoje, datas, scores, perfil, ultimoPeso] = await Promise.all([
      dailyLogModel.porData(patientId, hoje),
      dailyLogModel.datasComLog(patientId, 60),
      dailyLogModel.scores(patientId, 28),
      patientModel.perfil(patientId),
      dailyLogModel.ultimoPeso(patientId),
    ]);
    const streak = calcularStreak(datas, hoje);
    return res.json({
      hoje: logHoje,
      pesoAtualKg: ultimoPeso,
      streak,
      scores28dias: scores,
      metas: perfil ? {
        proteinaGkg: perfil.metaProteinaGkg,
        aguaMlKg: perfil.metaAguaMlKg,
        fonte: 'Diretrizes públicas gerais (ABESO / hidratação geral). Ajustáveis pelo seu profissional de saúde.',
      } : null,
      rodape: 'Conteúdo educativo. Não é recomendação médica. Consulte sempre seu médico.',
    });
  } catch (err) { next(err); }
}

module.exports = { registrar, listar, dashboard, recalcular };
