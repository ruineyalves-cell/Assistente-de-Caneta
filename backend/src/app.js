const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const routes = require('./routes');
const { apiLimiter } = require('./middleware/rateLimiter');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();

app.set('trust proxy', 1); // Railway/proxy — IP real para rate limit e auditoria
app.use(helmet());
// CORS: aceita CSV de origens (produção) ou o curinga "*" (dev). Quando
// o valor é apenas "*", passamos `origin: true` para o middleware refletir
// o Origin do request — modo compatível com `credentials: true` (a spec
// proíbe combinar Allow-Origin: * com credenciais literais).
const corsOrigemEnv = (process.env.CORS_ORIGIN || '').trim();
const corsOrigin = corsOrigemEnv === '*'
  ? true
  : corsOrigemEnv.split(',').map((o) => o.trim()).filter(Boolean);
app.use(cors({ origin: corsOrigin, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(apiLimiter);

app.get('/health', (_req, res) => res.json({ ok: true, servico: 'assistente-caneta-api', versao: '0.1.0' }));

app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
