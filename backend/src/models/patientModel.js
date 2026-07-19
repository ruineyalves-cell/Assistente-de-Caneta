const db = require('../config/db');
const { encryptField, decryptNumber } = require('../utils/crypto');

async function upsertPerfil(userId, {
  medicationId, doseAtual, frequencia, pesoInicialKg, alturaCm,
  declarouPrescricao, metaProteinaGkg, metaAguaMlKg,
  // Lote 31 — perfil estendido antes só local.
  eixoFarmacologico, identidadeGenero, sexoBiologico, ultimaDoseIso, metaPesoKg,
}) {
  const { rows } = await db.query(
    `INSERT INTO patient_profiles
       (user_id, medication_id, dose_atual, frequencia, peso_inicial_enc, altura_cm_enc,
        declarou_prescricao, meta_proteina_gkg, meta_agua_ml_kg,
        eixo_farmacologico, identidade_genero, sexo_biologico,
        ultima_dose_iso, meta_peso_kg_enc, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,COALESCE($8,1.20),COALESCE($9,35.00),
             $10,$11,$12,$13,$14,now())
     ON CONFLICT (user_id) DO UPDATE SET
       medication_id = COALESCE(EXCLUDED.medication_id, patient_profiles.medication_id),
       dose_atual = COALESCE(EXCLUDED.dose_atual, patient_profiles.dose_atual),
       frequencia = COALESCE(EXCLUDED.frequencia, patient_profiles.frequencia),
       peso_inicial_enc = COALESCE(EXCLUDED.peso_inicial_enc, patient_profiles.peso_inicial_enc),
       altura_cm_enc = COALESCE(EXCLUDED.altura_cm_enc, patient_profiles.altura_cm_enc),
       declarou_prescricao = EXCLUDED.declarou_prescricao,
       meta_proteina_gkg = COALESCE($8, patient_profiles.meta_proteina_gkg),
       meta_agua_ml_kg = COALESCE($9, patient_profiles.meta_agua_ml_kg),
       eixo_farmacologico = COALESCE(EXCLUDED.eixo_farmacologico, patient_profiles.eixo_farmacologico),
       identidade_genero = COALESCE(EXCLUDED.identidade_genero, patient_profiles.identidade_genero),
       sexo_biologico = COALESCE(EXCLUDED.sexo_biologico, patient_profiles.sexo_biologico),
       ultima_dose_iso = COALESCE(EXCLUDED.ultima_dose_iso, patient_profiles.ultima_dose_iso),
       meta_peso_kg_enc = COALESCE(EXCLUDED.meta_peso_kg_enc, patient_profiles.meta_peso_kg_enc),
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
      eixoFarmacologico ?? null,
      identidadeGenero ?? null,
      sexoBiologico ?? null,
      ultimaDoseIso ?? null,
      metaPesoKg != null ? encryptField(metaPesoKg) : null,
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
    // Lote 31 — perfil estendido.
    eixoFarmacologico: r.eixo_farmacologico || null,
    identidadeGenero: r.identidade_genero || null,
    sexoBiologico: r.sexo_biologico || null,
    ultimaDoseIso: r.ultima_dose_iso ? r.ultima_dose_iso.toISOString().slice(0, 10) : null,
    metaPesoKg: decryptNumber(r.meta_peso_kg_enc),
  };
}

module.exports = { upsertPerfil, perfil };
