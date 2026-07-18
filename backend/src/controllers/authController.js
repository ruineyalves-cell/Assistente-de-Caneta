const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');
const { z } = require('zod');
const { OAuth2Client } = require('google-auth-library');
const db = require('../config/db');
const userModel = require('../models/userModel');
const { signAccessToken } = require('../middleware/auth');
const { sha256 } = require('../utils/crypto');

// Lote 20 — Cliente OAuth do Google reaproveitado entre requisições.
// GOOGLE_OAUTH_CLIENT_IDS aceita CSV — para permitir simultaneamente o
// Web Client ID (usado como aud pelo google_sign_in Flutter) e o Android
// Client ID quando o app é assinado pela release keystore.
const _googleAudiences = (process.env.GOOGLE_OAUTH_CLIENT_IDS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const _googleClient = new OAuth2Client();

const registroSchema = z.object({
  nome: z.string().min(3).max(160),
  email: z.string().email(),
  senha: z.string().min(8, 'Senha deve ter no mínimo 8 caracteres').max(72),
  dataNascimento: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  role: z.enum(['paciente', 'profissional']).default('paciente'),
  // profissional:
  conselho: z.enum(['CRM', 'CRN']).optional(),
  registro: z.string().max(20).optional(),
  uf: z.string().length(2).optional(),
});

function maiorDeIdade(dataNascimento) {
  const nasc = new Date(`${dataNascimento}T00:00:00Z`);
  const hoje = new Date();
  const idade = (hoje - nasc) / (365.25 * 24 * 3600 * 1000);
  return idade >= 18;
}

async function emitirRefresh(userId) {
  const token = crypto.randomBytes(48).toString('base64url');
  const dias = Number(process.env.REFRESH_EXPIRES_DAYS) || 30;
  await db.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, now() + ($3 || ' days')::interval)`,
    [userId, sha256(token), String(dias)]
  );
  return token;
}

async function registrar(req, res, next) {
  try {
    const d = registroSchema.parse(req.body);
    if (!maiorDeIdade(d.dataNascimento)) {
      return res.status(403).json({ erro: 'O app é permitido apenas para maiores de 18 anos (Termos de Uso §1.3).' });
    }
    if (d.role === 'profissional' && (!d.conselho || !d.registro || !d.uf)) {
      return res.status(400).json({ erro: 'Profissional deve informar conselho (CRM/CRN), registro e UF.' });
    }
    const passwordHash = await bcrypt.hash(d.senha, 12);
    const user = await userModel.criar({
      email: d.email, passwordHash, role: d.role, nome: d.nome, dataNascimento: d.dataNascimento,
    });
    if (d.role === 'profissional') {
      await db.query(
        `INSERT INTO professional_profiles (user_id, conselho, registro, uf) VALUES ($1,$2,$3,$4)`,
        [user.id, d.conselho, d.registro, d.uf.toUpperCase()]
      );
    }
    const refresh = await emitirRefresh(user.id);
    return res.status(201).json({
      usuario: user,
      accessToken: signAccessToken({ id: user.id, role: d.role }),
      refreshToken: refresh,
      aviso: d.role === 'profissional'
        ? 'Registro profissional pendente de verificação (CRM/CRN). Acesso ao portal liberado após verificação.'
        : undefined,
    });
  } catch (err) { next(err); }
}

async function login(req, res, next) {
  try {
    const { email, senha } = z.object({ email: z.string().email(), senha: z.string() }).parse(req.body);
    const user = await userModel.porEmail(email);
    const ok = user && (await bcrypt.compare(senha, user.password_hash));
    if (!ok) return res.status(401).json({ erro: 'E-mail ou senha inválidos' });
    const refresh = await emitirRefresh(user.id);
    return res.json({
      usuario: { id: user.id, nome: user.nome, email: user.email, role: user.role },
      accessToken: signAccessToken({ id: user.id, role: user.role }),
      refreshToken: refresh,
    });
  } catch (err) { next(err); }
}

async function refresh(req, res, next) {
  try {
    const { refreshToken } = z.object({ refreshToken: z.string() }).parse(req.body);
    const { rows } = await db.query(
      `SELECT rt.user_id, u.role FROM refresh_tokens rt
        JOIN users u ON u.id = rt.user_id AND u.deleted_at IS NULL
       WHERE rt.token_hash = $1 AND rt.revoked_at IS NULL AND rt.expires_at > now()`,
      [sha256(refreshToken)]
    );
    if (!rows.length) return res.status(401).json({ erro: 'Refresh token inválido ou expirado' });
    return res.json({ accessToken: signAccessToken({ id: rows[0].user_id, role: rows[0].role }) });
  } catch (err) { next(err); }
}

/**
 * Lote 20 — Login social via provedor OAuth.
 *
 * Aceita `provedor: 'google'` (extensível a 'apple'). Valida o idToken
 * assinado pelo provedor, extrai o email verificado e cria/associa o
 * usuário. Retorna o mesmo shape do /auth/login para o Flutter reusar o
 * fluxo.
 *
 * Segurança:
 *   - Valida assinatura via biblioteca oficial do Google (não é só
 *     `jwt.decode`).
 *   - Só aceita audiences (aud) da lista GOOGLE_OAUTH_CLIENT_IDS.
 *   - Só aceita emails verificados pelo Google.
 *   - Se o email já existe com password_hash, apenas gera novos tokens
 *     (associação implícita — usuário está provando que é dono do email).
 */
const oauthSchema = z.object({
  provedor: z.enum(['google']),
  idToken: z.string().min(20),
  email: z.string().email().optional(),
  nome: z.string().max(160).optional(),
});

async function oauthSocial(req, res, next) {
  try {
    const d = oauthSchema.parse(req.body);

    if (d.provedor !== 'google') {
      return res.status(400).json({ erro: 'Provedor OAuth não suportado ainda.' });
    }
    if (_googleAudiences.length === 0) {
      return res.status(503).json({
        erro:
          'Login social ainda não configurado no servidor. Defina GOOGLE_OAUTH_CLIENT_IDS.',
      });
    }

    let payload;
    try {
      const ticket = await _googleClient.verifyIdToken({
        idToken: d.idToken,
        audience: _googleAudiences,
      });
      payload = ticket.getPayload();
    } catch (e) {
      return res.status(401).json({ erro: 'Token do Google inválido ou expirado.' });
    }

    if (!payload || !payload.email || payload.email_verified !== true) {
      return res.status(401).json({ erro: 'Conta Google sem email verificado.' });
    }

    const emailNorm = payload.email.toLowerCase();
    const nome = (payload.name || d.nome || emailNorm.split('@')[0]).slice(0, 160);

    let user = await userModel.porEmail(emailNorm);
    if (!user) {
      // Cria conta social: password_hash é um marcador não-logável
      // (bcrypt de random) — impede login por senha em contas sociais.
      const marker = await bcrypt.hash(
        `oauth:google:${payload.sub}:${crypto.randomBytes(16).toString('hex')}`,
        4
      );
      const dataNascimento = '1900-01-01'; // desconhecida na criação; usuário completa no perfil
      user = await userModel.criar({
        email: emailNorm,
        passwordHash: marker,
        role: 'paciente',
        nome,
        dataNascimento,
      });
    }

    const refresh = await emitirRefresh(user.id);
    return res.json({
      usuario: {
        id: user.id,
        nome: user.nome || nome,
        email: user.email || emailNorm,
        role: user.role || 'paciente',
      },
      accessToken: signAccessToken({ id: user.id, role: user.role || 'paciente' }),
      refreshToken: refresh,
      social: {
        provedor: 'google',
        criouConta: !user.created_at ? false : new Date(user.created_at).getTime() > Date.now() - 30_000,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    const { refreshToken } = z.object({ refreshToken: z.string() }).parse(req.body);
    await db.query(`UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1`, [sha256(refreshToken)]);
    return res.json({ ok: true });
  } catch (err) { next(err); }
}

module.exports = { registrar, login, refresh, logout, oauthSocial };
