/**
 * Logger estruturado + captura opcional de erros (P1 do relatório).
 *
 * Uso:
 *   const { logger, capturarErro } = require('../utils/logger');
 *   logger.info({ evento: 'login_ok', userId }, 'login realizado');
 *   logger.warn({ evento: 'login_falha', email }, 'senha inválida');
 *   capturarErro(err, { rota: '/api/pacientes/perfil' });
 *
 * Por que estruturado (JSON) em vez de console.log:
 *   - Filtragem em produção (`level=warn`, `evento=login_falha`)
 *   - Ingestão trivial em Datadog / Grafana Loki / Papertrail
 *   - Correlação com métricas
 *
 * Sentry é OPT-IN: só ativa se SENTRY_DSN estiver setada. Sem DSN,
 * `capturarErro` só loga localmente — nenhum dado sai do servidor.
 */

const pino = require('pino');

const nivel = process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug');

// Em dev, formato humano legível. Em prod, JSON puro pra ingestão.
const transport =
  process.env.NODE_ENV === 'production'
    ? undefined
    : {
        target: 'pino-pretty',
        options: { colorize: true, translateTime: 'HH:MM:ss', ignore: 'pid,hostname' },
      };

const logger = pino({
  level: nivel,
  redact: {
    // Nunca logar campos sensíveis, mesmo por acidente
    paths: [
      'password',
      'senha',
      'password_hash',
      'passwordHash',
      'accessToken',
      'refreshToken',
      'refresh_token',
      'access_token',
      'idToken',
      'authorization',
      'imagemBase64',
      'req.headers.authorization',
      'req.body.senha',
      'req.body.password',
      'req.body.refreshToken',
      'req.body.imagemBase64',
    ],
    censor: '[REDACTED]',
  },
  transport,
});

let sentry = null;
const dsn = process.env.SENTRY_DSN;
if (dsn) {
  try {
    sentry = require('@sentry/node');
    sentry.init({
      dsn,
      environment: process.env.NODE_ENV || 'development',
      tracesSampleRate: 0, // MVP: só erros, sem tracing (evita custo)
      beforeSend(event) {
        // Belt-and-suspenders: se algum campo sensível vazar via stack,
        // rasgar antes de mandar pro Sentry.
        if (event.request?.data && typeof event.request.data === 'object') {
          for (const k of ['senha', 'password', 'refreshToken', 'imagemBase64']) {
            if (event.request.data[k]) event.request.data[k] = '[REDACTED]';
          }
        }
        return event;
      },
    });
    logger.info({ evento: 'sentry_iniciado' }, 'Sentry ativo');
  } catch (e) {
    logger.warn({ err: e.message }, 'SENTRY_DSN definida mas @sentry/node não carregou');
  }
}

/**
 * Loga o erro localmente e envia pro Sentry (se configurado).
 * `contexto` vira breadcrumb + extra data.
 */
function capturarErro(err, contexto = {}) {
  logger.error({ err, ...contexto }, err?.message || 'erro capturado');
  if (sentry) {
    sentry.captureException(err, { extra: contexto });
  }
}

/**
 * Eventos de segurança (login falha, lockout, refresh reuse, CORS bloqueado).
 * Nível "warn" pra facilitar alertas ("me avise se aparecerem >10/min").
 */
function logSeguranca(evento, contexto = {}) {
  logger.warn({ evento, ...contexto }, `[seguranca] ${evento}`);
}

module.exports = { logger, capturarErro, logSeguranca, sentry };
