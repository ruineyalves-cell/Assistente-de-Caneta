const medicationModel = require('../models/medicationModel');

/** GET /api/medicacoes — catálogo público (dados de bula/Anvisa). */
async function listar(_req, res, next) {
  try {
    const medicacoes = await medicationModel.listarAtivas();
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
    return res.json({ medicacao: med });
  } catch (err) { next(err); }
}

module.exports = { listar, detalhe };
