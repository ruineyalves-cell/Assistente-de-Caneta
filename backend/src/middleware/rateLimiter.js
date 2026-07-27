const rateLimit = require('express-rate-limit');
const { logSeguranca } = require('../utils/logger');

const windowMs = (Number(process.env.RATE_LIMIT_WINDOW_MIN) || 15) * 60 * 1000;

/** Limite geral da API. */
const apiLimiter = rateLimit({
  windowMs,
  max: Number(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { erro: 'Muitas requisições. Tente novamente em alguns minutos.' },
});

/** Limite agressivo para login/registro (anti força bruta). */
const authLimiter = rateLimit({
  windowMs,
  max: Number(process.env.RATE_LIMIT_AUTH_MAX) || 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { erro: 'Muitas tentativas de autenticação. Aguarde e tente novamente.' },
});

/**
 * Rate limit específico para /api/ia/* (Lote G1).
 *
 * Cada chamada consome uma cota da Gemini API. Sem limite por-usuário,
 * uma conta comprometida (ou bug do app em loop) poderia:
 *   - Estourar cota gratuita do dia (1500 req) em segundos
 *   - Se plano pago, gerar fatura surpresa
 *
 * Chave = userId (definido pelo requireAuth). Fallback pra IP se
 * a rota IA for chamada sem auth (não deveria acontecer, mas defense
 * in depth). Janela curta (1 min) porque scanner é ação humana — 15
 * req/min é gerosíssimo pra uso legítimo.
 */
const iaLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.RATE_LIMIT_IA_MAX) || 15,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.id || req.ip,
  handler: (req, res) => {
    logSeguranca('ia_rate_limit', {
      userId: req.user?.id || null,
      ip: req.ip,
      rota: req.path,
    });
    return res.status(429).json({
      erro: 'Muitas análises de imagem em pouco tempo. Aguarde 1 minuto.',
    });
  },
});

/**
 * Rate limit para /api/assinaturas/validar.
 *
 * Cada validação faz round-trip à Play API (rate limit deles é 200k/dia
 * — folgado, mas gasta cota + latência). Não faz sentido um app legítimo
 * validar mais que ~5x/min: uma vez após purchase, quando muito o
 * usuário reabre a compra. 20/min por usuário é gerenciável.
 */
const subscriptionLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.RATE_LIMIT_SUB_MAX) || 20,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.id || req.ip,
  handler: (req, res) => {
    logSeguranca('subscription_rate_limit', {
      userId: req.user?.id || null,
      ip: req.ip,
    });
    return res.status(429).json({
      erro: 'Muitas validações em pouco tempo. Aguarde 1 minuto.',
    });
  },
});

module.exports = { apiLimiter, authLimiter, iaLimiter, subscriptionLimiter };
