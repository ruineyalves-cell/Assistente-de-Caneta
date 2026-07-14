/**
 * Middleware LGPD:
 *  1. audit(action, resource) — registra acesso a dados de saúde (art. 37).
 *  2. requireConsent — bloqueia tratamento de dados de saúde sem consentimento
 *     'privacidade_saude' ativo (art. 11, I).
 */
const db = require('../config/db');

/** Grava trilha de auditoria. resourceOwner: fn(req) => uuid do titular. */
function audit(action, resource, resourceOwner = (req) => req.user?.id) {
  return async (req, _res, next) => {
    try {
      await db.query(
        `INSERT INTO audit_logs (actor_user_id, actor_role, action, resource, resource_owner, detalhe, ip)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [
          req.user?.id || null,
          req.user?.role || null,
          action,
          resource,
          resourceOwner(req) || null,
          JSON.stringify({ path: req.originalUrl, method: req.method }),
          req.ip,
        ]
      );
    } catch (err) {
      // auditoria não pode derrubar a request, mas o erro precisa aparecer
      console.error('[lgpd/audit] falha ao gravar auditoria:', err.message);
    }
    next();
  };
}

/** Exige consentimento 'privacidade_saude' aceito e não revogado. */
async function requireConsent(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT aceito FROM consents
        WHERE user_id = $1 AND tipo = 'privacidade_saude'
        ORDER BY created_at DESC LIMIT 1`,
      [req.user.id]
    );
    if (!rows.length || rows[0].aceito !== true) {
      return res.status(451).json({
        erro: 'Consentimento LGPD necessário',
        detalhe: 'Aceite a Política de Privacidade (dados de saúde) em POST /api/lgpd/consentimento antes de usar este recurso.',
      });
    }
    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = { audit, requireConsent };
