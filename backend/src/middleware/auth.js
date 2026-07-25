const jwt = require('jsonwebtoken');

/**
 * Exige JWT válido. Popula req.user = { id, role }.
 *
 * SEGURANÇA: `algorithms: ['HS256']` explícito bloqueia algorithm
 * confusion attack (ex.: token forjado com alg='none'). jsonwebtoken v9+
 * já rejeita 'none' por padrão, mas explícito é sempre mais seguro
 * — se algum dia trocarmos para RS256, o allowlist é única fonte de
 * verdade e evita aceitar tokens HS256 assinados com a public key.
 */
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ erro: 'Token ausente' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ['HS256'],
    });
    req.user = { id: payload.sub, role: payload.role };
    return next();
  } catch {
    return res.status(401).json({ erro: 'Token inválido ou expirado' });
  }
}

/** Exige um dos papéis informados. Usar após requireAuth. */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ erro: 'Acesso negado para este perfil' });
    }
    return next();
  };
}

function signAccessToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES || '15m',
  });
}

module.exports = { requireAuth, requireRole, signAccessToken };
