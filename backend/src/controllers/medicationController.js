const medicationModel = require('../models/medicationModel');

// Lote H3 — Catálogo público de GLP-1 é praticamente estático: uma dose
// nova entra em ~1x/ano. Dizendo pro cliente/CDN cachear por 1h + 1 dia
// stale-while-revalidate, o backend deixa de servir a mesma query em
// toda abertura do app. `public` autoriza CDN/proxy; `must-revalidate`
// garante que expirações forcem re-fetch (em vez de servir infinitamente
// se algum proxy interpretar mal).
const CACHE_CATALOGO = 'public, max-age=3600, stale-while-revalidate=86400, must-revalidate';

/** GET /api/medicacoes — catálogo público (dados de bula/Anvisa). */
async function listar(_req, res, next) {
  try {
    const medicacoes = await medicationModel.listarAtivas();
    res.set('Cache-Control', CACHE_CATALOGO);
    return res.json({
      medicacoes,
      fonte: 'Bulas oficiais (Anvisa) e preços de referência CMED — dados informativos, sujeitos a atualização.',
      rodape: 'Informações educativas. Não constituem recomendação. Medicamentos exigem receita retida (IN Anvisa 360/2025).',
    });
  } catch (err) { next(err); }
}

/** GET /api/medicacoes/:id */
async function detalhe(req, res, next) {
  try {
    const med = await medicationModel.porId(Number(req.params.id));
    if (!med) return res.status(404).json({ erro: 'Medicação não encontrada' });
    res.set('Cache-Control', CACHE_CATALOGO);
    return res.json({ medicacao: med });
  } catch (err) { next(err); }
}

module.exports = { listar, detalhe };
