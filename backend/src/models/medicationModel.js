const db = require('../config/db');

/** Lista medicações selecionáveis (aprovadas Anvisa). */
async function listarAtivas() {
  const { rows } = await db.query(
    `SELECT id, nome_comercial, principio_ativo, fabricante, status_anvisa, categoria,
            indicacoes, frequencia_padrao, via, doses_disponiveis, preco_referencia,
            receituario, bula_url, observacoes
       FROM medications
      WHERE ativo = true AND status_anvisa = 'aprovado'
      ORDER BY nome_comercial`
  );
  return rows;
}

async function porId(id) {
  const { rows } = await db.query(`SELECT * FROM medications WHERE id = $1`, [id]);
  return rows[0] || null;
}

module.exports = { listarAtivas, porId };
