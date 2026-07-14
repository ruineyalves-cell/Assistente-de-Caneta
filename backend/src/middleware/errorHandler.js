const { ZodError } = require('zod');

/** 404 padrão. */
function notFound(_req, res) {
  res.status(404).json({ erro: 'Rota não encontrada' });
}

/** Handler central de erros — nunca vaza stack ou dados sensíveis ao cliente. */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      erro: 'Dados inválidos',
      detalhes: err.errors.map((e) => ({ campo: e.path.join('.'), problema: e.message })),
    });
  }
  if (err.code === '23505') { // unique_violation (Postgres)
    return res.status(409).json({ erro: 'Registro já existe' });
  }
  console.error(`[erro] ${req.method} ${req.originalUrl}:`, err);
  return res.status(err.status || 500).json({ erro: err.expose ? err.message : 'Erro interno' });
}

module.exports = { notFound, errorHandler };
