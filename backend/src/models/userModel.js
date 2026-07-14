const db = require('../config/db');

async function criar({ email, passwordHash, role, nome, dataNascimento }) {
  const { rows } = await db.query(
    `INSERT INTO users (email, password_hash, role, nome, data_nascimento)
     VALUES ($1,$2,$3,$4,$5)
     RETURNING id, email, role, nome, created_at`,
    [email.toLowerCase(), passwordHash, role, nome, dataNascimento]
  );
  return rows[0];
}

async function porEmail(email) {
  const { rows } = await db.query(
    `SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL`,
    [email.toLowerCase()]
  );
  return rows[0] || null;
}

async function porId(id) {
  const { rows } = await db.query(
    `SELECT id, email, role, nome, data_nascimento, created_at
       FROM users WHERE id = $1 AND deleted_at IS NULL`,
    [id]
  );
  return rows[0] || null;
}

/** LGPD art. 18, VI — soft delete imediato + agenda purga definitiva em 30 dias. */
async function solicitarExclusao(id) {
  await db.query(
    `UPDATE users
        SET deleted_at = now(),
            purge_after = now() + interval '30 days',
            email = 'excluido+' || id || '@anonimizado.local'
      WHERE id = $1`,
    [id]
  );
  await db.query(`UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1`, [id]);
}

module.exports = { criar, porEmail, porId, solicitarExclusao };
