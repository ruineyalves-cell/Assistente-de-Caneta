/**
 * Endpoints LGPD — direitos do titular (arts. 17-22) e consentimento (arts. 8º e 11).
 */
const { z } = require('zod');
const db = require('../config/db');
const userModel = require('../models/userModel');
const patientModel = require('../models/patientModel');
const dailyLogModel = require('../models/dailyLogModel');

const consentSchema = z.object({
  tipo: z.enum(['termos_uso', 'privacidade_saude', 'disclaimer_medico']),
  versaoDoc: z.string().max(20),
  aceito: z.boolean(),
});

/** POST /api/lgpd/consentimento — registra aceite ou revogação. */
async function registrarConsentimento(req, res, next) {
  try {
    const d = consentSchema.parse(req.body);
    await db.query(
      `INSERT INTO consents (user_id, tipo, versao_doc, aceito, ip, user_agent)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [req.user.id, d.tipo, d.versaoDoc, d.aceito, req.ip, (req.headers['user-agent'] || '').slice(0, 300)]
    );
    return res.status(201).json({
      ok: true,
      efeito: d.aceito ? 'Consentimento registrado.' :
        'Revogação registrada — a coleta de dados de saúde foi interrompida. Você pode solicitar a exclusão total em DELETE /api/lgpd/conta.',
    });
  } catch (err) { next(err); }
}

/** GET /api/lgpd/consentimentos — histórico do próprio titular. */
async function listarConsentimentos(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT tipo, versao_doc, aceito, created_at FROM consents
        WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.user.id]
    );
    return res.json({ consentimentos: rows });
  } catch (err) { next(err); }
}

/** GET /api/lgpd/exportar — portabilidade (art. 18, V): JSON completo. */
async function exportarDados(req, res, next) {
  try {
    const [usuario, perfil, logs, scores] = await Promise.all([
      userModel.porId(req.user.id),
      req.user.role === 'paciente' ? patientModel.perfil(req.user.id) : null,
      req.user.role === 'paciente' ? dailyLogModel.listar(req.user.id, { limite: 100000 }) : [],
      req.user.role === 'paciente' ? dailyLogModel.scores(req.user.id, 100000) : [],
    ]);
    const { rows: consentimentos } = await db.query(
      `SELECT tipo, versao_doc, aceito, created_at FROM consents WHERE user_id = $1 ORDER BY created_at`,
      [req.user.id]
    );
    res.setHeader('Content-Disposition', 'attachment; filename="meus-dados-assistente-caneta.json"');
    return res.json({
      exportadoEm: new Date().toISOString(),
      baseLegal: 'LGPD art. 18, V (portabilidade)',
      usuario, perfil, consentimentos, registrosDiarios: logs, scores,
    });
  } catch (err) { next(err); }
}

/** GET /api/lgpd/acessos — quem acessou meus dados (art. 18, VII). */
async function listarAcessos(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT a.action, a.resource, a.created_at, a.actor_role,
              u.nome AS acessado_por
         FROM audit_logs a
         LEFT JOIN users u ON u.id = a.actor_user_id
        WHERE a.resource_owner = $1
        ORDER BY a.created_at DESC
        LIMIT 500`,
      [req.user.id]
    );
    return res.json({ acessos: rows });
  } catch (err) { next(err); }
}

/** DELETE /api/lgpd/conta — direito de eliminação (art. 18, VI). */
async function excluirConta(req, res, next) {
  try {
    const { confirmo } = z.object({ confirmo: z.literal(true) }).parse(req.body);
    void confirmo;
    await userModel.solicitarExclusao(req.user.id);
    return res.json({
      ok: true,
      efeito: 'Conta desativada imediatamente. Dados pessoais serão eliminados definitivamente em até 30 dias (Política de Privacidade §7). Backups expiram em ciclo de até 35 dias.',
    });
  } catch (err) { next(err); }
}

module.exports = { registrarConsentimento, listarConsentimentos, exportarDados, listarAcessos, excluirConta };
