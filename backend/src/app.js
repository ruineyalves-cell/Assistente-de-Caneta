const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const routes = require('./routes');
const { apiLimiter } = require('./middleware/rateLimiter');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();

app.set('trust proxy', 1); // Render/proxy — IP real para rate limit e auditoria
app.use(helmet());

// Compressão gzip/brotli — reduz payload em 60-70% em 4G. Especialmente
// forte no /dashboard e /logs (JSON grande). Skip em respostas < 1KB.
app.use(compression({ threshold: 1024 }));

/**
 * CORS estrito.
 *
 * SEGURANÇA (S2): Com `credentials:true` + curinga refletido, qualquer
 * site na web pode chamar a API usando as credenciais do usuário. Como
 * a autenticação é via header `Authorization` (não cookie), o impacto
 * hoje é limitado, mas o portal médico web vai usar sessão — então
 * fechamos AGORA.
 *
 * `CORS_ORIGIN` (env var): CSV das origens permitidas em produção.
 * Ex.: "https://www.recorpo.com.br,https://recorpo.com.br".
 *
 * Modo estrito: origem sem match → CORS bloqueia (browser rejeita).
 * Requests server-to-server (curl/Postman/apps mobile) NÃO enviam
 * `Origin` e não são afetados — o app Flutter continua funcionando.
 *
 * Retro-compat de dev: se `CORS_ORIGIN` vier vazio OU exatamente "*",
 * cai em `origin:true` (reflete Origin) e loga um warn.
 */
const corsOrigemEnv = (process.env.CORS_ORIGIN || '').trim();
const corsOrigemLista = corsOrigemEnv
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

let corsOrigin;
if (!corsOrigemEnv || corsOrigemEnv === '*') {
  if (process.env.NODE_ENV === 'production') {
    console.warn(
      '[cors] AVISO: CORS_ORIGIN aberto em produção. Defina domínios explícitos ' +
        '(ex.: https://www.recorpo.com.br,https://recorpo.com.br).'
    );
  }
  corsOrigin = true; // reflete Origin (dev / retro-compat)
} else {
  corsOrigin = (origin, cb) => {
    if (!origin) return cb(null, true); // apps mobile e curl passam sem Origin
    if (corsOrigemLista.includes(origin)) return cb(null, true);
    return cb(new Error(`CORS bloqueado para origem ${origin}`));
  };
}
app.use(cors({ origin: corsOrigin, credentials: true }));

/**
 * Body parsers por rota.
 *
 * SEGURANÇA + BUG (S3): antes existia UM único `express.json({limit:'1mb'})`
 * global. O schema de IA aceita imagens até 20 MB base64, mas fotos de
 * câmera moderna passam de 1 MB → o endpoint quebrava com 413. Além de
 * bug funcional, limite muito alto em rotas leves seria vetor de DoS.
 *
 * Solução: 10 MB só nas rotas /api/ia/*; 256 KB no restante (mais
 * apertado que antes; nenhum endpoint legítimo envia mais que isso).
 */
app.use('/api/ia', express.json({ limit: '10mb' }));
app.use(express.json({ limit: '256kb' }));

app.use(apiLimiter);

app.get('/health', (_req, res) => res.json({ ok: true, servico: 'assistente-caneta-api', versao: '0.1.0' }));

app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
