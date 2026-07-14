const db = require('../config/db');

/** Paciente convida profissional (por e-mail já cadastrado). */
async function convidar(patientId, professionalId) {
  const { rows } = await db.query(
    `INSERT INTO patient_professional_links (patient_id, professional_id, status)
     VALUES ($1,$2,'ativo')
     ON CONFLICT (patient_id, professional_id)
       DO UPDATE SET status = 'ativo', revogado_em = NULL
     RETURNING id, status`,
    [patientId, professionalId]
  );
  return rows[0];
}

async function revogar(patientId, professionalId) {
  await db.query(
    `UPDATE patient_professional_links
        SET status = 'revogado', revogado_em = now()
      WHERE patient_id = $1 AND professional_id = $2`,
    [patientId, professionalId]
  );
}

/** O profissional tem vínculo ativo com este paciente? */
async function vinculoAtivo(professionalId, patientId) {
  const { rows } = await db.query(
    `SELECT 1 FROM patient_professional_links
      WHERE professional_id = $1 AND patient_id = $2 AND status = 'ativo'`,
    [professionalId, patientId]
  );
  return rows.length > 0;
}

async function pacientesDoProfissional(professionalId) {
  const { rows } = await db.query(
    `SELECT u.id, u.nome, u.email, l.created_at AS vinculado_em
       FROM patient_professional_links l
       JOIN users u ON u.id = l.patient_id AND u.deleted_at IS NULL
      WHERE l.professional_id = $1 AND l.status = 'ativo'
      ORDER BY u.nome`,
    [professionalId]
  );
  return rows;
}

async function profissionaisDoPaciente(patientId) {
  const { rows } = await db.query(
    `SELECT u.id, u.nome, u.email, pp.conselho, pp.registro, pp.uf, pp.verificado, l.status
       FROM patient_professional_links l
       JOIN users u ON u.id = l.professional_id AND u.deleted_at IS NULL
       LEFT JOIN professional_profiles pp ON pp.user_id = u.id
      WHERE l.patient_id = $1 AND l.status = 'ativo'`,
    [patientId]
  );
  return rows;
}

module.exports = { convidar, revogar, vinculoAtivo, pacientesDoProfissional, profissionaisDoPaciente };
