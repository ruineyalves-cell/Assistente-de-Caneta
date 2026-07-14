const db = require('../config/db');
const { encryptField, decryptNumber } = require('../utils/crypto');

async function upsertPerfil(userId, { medicationId, doseAtual, frequencia, pesoInicialKg, alturaCm, declarouPrescricao, metaProteinaGkg, metaAguaMlKg }) {
  const { rows } = await db.query(
    `INSERT INTO patient_profiles
       (user_id, medication_id, dose_atual, frequencia, peso_inicial_enc, altura_cm_enc,
        declarou_prescricao, meta_proteina_gkg, meta_agua_ml_kg, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,COALESCE($8,1.20),COALESCE($9,35.00),now())
     ON CONFLICT (user_id) DO UPDATE SET
       medication_id = COALESCE(EXCLUDED.medication_id, patient_profiles.medication_id),
       dose_atual = COALESCE(EXCLUDED.dose_atual, patient_profiles.dose_atual),
       frequencia = COALESCE(EXCLUDED.frequencia, patient_profiles.frequencia),
       peso_inicial_enc = COALESCE(EXCLUDED.peso_inicial_enc, patient_profiles.peso_inicial_enc),
       altura_cm_enc = COALESCE(EXCLUDED.altura_cm_enc, patient_profiles.altura_cm_enc),
       declarou_prescricao = EXCLUDED.declarou_prescricao,
       meta_proteina_gkg = COALESCE($8, patient_profiles.meta_proteina_gkg),
       meta_agua_ml_kg = COALESCE($9, patient_profiles.meta_agua_ml_kg),
       updated_at = now()
     RETURNING user_id`,
    [
      userId,
      medicationId ?? null,
      doseAtual ?? null,
      frequencia ?? null,
      pesoInicialKg != null ? encryptField(pesoInicialKg) : null,
      alturaCm != null ? encryptField(alturaCm) : null,
      declarouPrescricao === true,
      metaProteinaGkg ?? null,
      metaAguaMlKg ?? null,
    ]
  );
  return rows[0];
}

async function perfil(userId) {
  const { rows } = await db.query(
    `SELECT p.*, m.nome_comercial, m.principio_ativo, m.frequencia_padrao, m.categoria
       FROM patient_profiles p
       LEFT JOIN medications m ON m.id = p.medication_id
      WHERE p.user_id = $1`,
    [userId]
  );
  if (!rows.length) return null;
  const r = rows[0];
  return {
    userId: r.user_id,
    medicacao: r.medication_id
      ? { id: r.medication_id, nome: r.nome_comercial, principioAtivo: r.principio_ativo, categoria: r.categoria, frequenciaPadrao: r.frequencia_padrao }
      : null,
    doseAtual: r.dose_atual,
    frequencia: r.frequencia,
    pesoInicialKg: decryptNumber(r.peso_inicial_enc),
    alturaCm: decryptNumber(r.altura_cm_enc),
    metaProteinaGkg: Number(r.meta_proteina_gkg),
    metaAguaMlKg: Number(r.meta_agua_ml_kg),
    declarouPrescricao: r.declarou_prescricao,
  };
}

module.exports = { upsertPerfil, perfil };
