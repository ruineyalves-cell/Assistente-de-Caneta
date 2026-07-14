/**
 * Portal do Profissional — SOMENTE LEITURA (Termos §4; matriz de responsabilidade #8).
 * Todo acesso a dados de paciente é auditado (LGPD art. 37).
 */
const db = require('../config/db');
const linkModel = require('../models/linkModel');
const dailyLogModel = require('../models/dailyLogModel');
const patientModel = require('../models/patientModel');
const userModel = require('../models/userModel');
const { gerarRelatorio } = require('../utils/pdf');
const { calcularStreak } = require('../utils/metrics');

/** Bloqueia profissional não verificado. */
async function exigirVerificado(req, res) {
  const { rows } = await db.query(
    `SELECT verificado FROM professional_profiles WHERE user_id = $1`, [req.user.id]
  );
  if (!rows.length || !rows[0].verificado) {
    res.status(403).json({ erro: 'Registro profissional (CRM/CRN) ainda não verificado.' });
    return false;
  }
  return true;
}

/** Garante vínculo ativo criado pelo paciente. */
async function exigirVinculo(req, res, patientId) {
  if (!(await linkModel.vinculoAtivo(req.user.id, patientId))) {
    res.status(403).json({ erro: 'Sem vínculo ativo com este paciente (o convite parte do paciente).' });
    return false;
  }
  return true;
}

/** GET /api/portal/pacientes */
async function listarPacientes(req, res, next) {
  try {
    if (!(await exigirVerificado(req, res))) return;
    const pacientes = await linkModel.pacientesDoProfissional(req.user.id);
    return res.json({ pacientes });
  } catch (err) { next(err); }
}

/** GET /api/portal/pacientes/:id — dashboard read-only do paciente. */
async function verPaciente(req, res, next) {
  try {
    if (!(await exigirVerificado(req, res))) return;
    const patientId = req.params.id;
    if (!(await exigirVinculo(req, res, patientId))) return;

    const [perfil, logs, scores, datas] = await Promise.all([
      patientModel.perfil(patientId),
      dailyLogModel.listar(patientId, { limite: 60 }),
      dailyLogModel.scores(patientId, 28),
      dailyLogModel.datasComLog(patientId, 60),
    ]);
    return res.json({
      perfil, logs, scores,
      streak: calcularStreak(datas, new Date().toISOString().slice(0, 10)),
      aviso: 'Dados autodeclarados pelo paciente. Acesso somente-leitura, registrado em auditoria.',
    });
  } catch (err) { next(err); }
}

/** GET /api/portal/pacientes/:id/relatorio.pdf */
async function relatorioPdf(req, res, next) {
  try {
    if (!(await exigirVerificado(req, res))) return;
    const patientId = req.params.id;
    if (!(await exigirVinculo(req, res, patientId))) return;

    const [paciente, perfil, logs, scores, datas] = await Promise.all([
      userModel.porId(patientId),
      patientModel.perfil(patientId),
      dailyLogModel.listar(patientId, { limite: 90 }),
      dailyLogModel.scores(patientId, 28),
      dailyLogModel.datasComLog(patientId, 60),
    ]);
    const pdf = await gerarRelatorio({
      paciente, perfil, logs, scores,
      streak: calcularStreak(datas, new Date().toISOString().slice(0, 10)),
    });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="relatorio-${patientId.slice(0, 8)}.pdf"`);
    return res.send(pdf);
  } catch (err) { next(err); }
}

module.exports = { listarPacientes, verPaciente, relatorioPdf };
