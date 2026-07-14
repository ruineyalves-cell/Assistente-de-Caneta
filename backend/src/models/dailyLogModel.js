const db = require('../config/db');
const { encryptField, decryptField, decryptNumber } = require('../utils/crypto');

async function upsert(patientId, logDate, { pesoKg, proteinaG, aguaMl, alimentos, doseAplicada, efeitos }) {
  const { rows } = await db.query(
    `INSERT INTO daily_logs
       (patient_id, log_date, peso_kg_enc, proteina_g_enc, agua_ml_enc, alimentos_enc, dose_aplicada, efeitos_enc, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,now())
     ON CONFLICT (patient_id, log_date) DO UPDATE SET
       peso_kg_enc    = COALESCE(EXCLUDED.peso_kg_enc,    daily_logs.peso_kg_enc),
       proteina_g_enc = COALESCE(EXCLUDED.proteina_g_enc, daily_logs.proteina_g_enc),
       agua_ml_enc    = COALESCE(EXCLUDED.agua_ml_enc,    daily_logs.agua_ml_enc),
       alimentos_enc  = COALESCE(EXCLUDED.alimentos_enc,  daily_logs.alimentos_enc),
       dose_aplicada  = EXCLUDED.dose_aplicada OR daily_logs.dose_aplicada,
       efeitos_enc    = COALESCE(EXCLUDED.efeitos_enc,    daily_logs.efeitos_enc),
       updated_at     = now()
     RETURNING id, log_date`,
    [
      patientId, logDate,
      pesoKg != null ? encryptField(pesoKg) : null,
      proteinaG != null ? encryptField(proteinaG) : null,
      aguaMl != null ? encryptField(aguaMl) : null,
      alimentos ? encryptField(alimentos) : null,
      doseAplicada === true,
      efeitos ? encryptField(efeitos) : null,
    ]
  );
  return rows[0];
}

function descriptografar(row) {
  return {
    id: row.id,
    data: row.log_date,
    pesoKg: decryptNumber(row.peso_kg_enc),
    proteinaG: decryptNumber(row.proteina_g_enc),
    aguaMl: decryptNumber(row.agua_ml_enc),
    alimentos: decryptField(row.alimentos_enc),
    doseAplicada: row.dose_aplicada,
    efeitos: decryptField(row.efeitos_enc),
  };
}

async function listar(patientId, { desde, ate, limite = 90 }) {
  const { rows } = await db.query(
    `SELECT * FROM daily_logs
      WHERE patient_id = $1
        AND ($2::date IS NULL OR log_date >= $2)
        AND ($3::date IS NULL OR log_date <= $3)
      ORDER BY log_date DESC
      LIMIT $4`,
    [patientId, desde || null, ate || null, limite]
  );
  return rows.map(descriptografar);
}

async function porData(patientId, logDate) {
  const { rows } = await db.query(
    `SELECT * FROM daily_logs WHERE patient_id = $1 AND log_date = $2`,
    [patientId, logDate]
  );
  return rows.length ? descriptografar(rows[0]) : null;
}

async function datasComLog(patientId, dias = 60) {
  const { rows } = await db.query(
    `SELECT to_char(log_date,'YYYY-MM-DD') AS d FROM daily_logs
      WHERE patient_id = $1 AND log_date >= current_date - $2::int
      ORDER BY log_date`,
    [patientId, dias]
  );
  return rows.map((r) => r.d);
}

/** Último peso conhecido (para metas quando o dia não tem peso). */
async function ultimoPeso(patientId) {
  const { rows } = await db.query(
    `SELECT peso_kg_enc FROM daily_logs
      WHERE patient_id = $1 AND peso_kg_enc IS NOT NULL
      ORDER BY log_date DESC LIMIT 1`,
    [patientId]
  );
  return rows.length ? decryptNumber(rows[0].peso_kg_enc) : null;
}

async function salvarScore(patientId, logDate, { score, componentes, alertas }) {
  await db.query(
    `INSERT INTO compliance_scores (patient_id, log_date, score, componentes, alertas)
     VALUES ($1,$2,$3,$4,$5)
     ON CONFLICT (patient_id, log_date) DO UPDATE SET
       score = EXCLUDED.score, componentes = EXCLUDED.componentes,
       alertas = EXCLUDED.alertas, created_at = now()`,
    [patientId, logDate, score, JSON.stringify(componentes), JSON.stringify(alertas)]
  );
}

async function scores(patientId, dias = 28) {
  const { rows } = await db.query(
    `SELECT to_char(log_date,'YYYY-MM-DD') AS data, score, componentes, alertas
       FROM compliance_scores
      WHERE patient_id = $1 AND log_date >= current_date - $2::int
      ORDER BY log_date DESC`,
    [patientId, dias]
  );
  return rows;
}

module.exports = { upsert, listar, porData, datasComLog, ultimoPeso, salvarScore, scores };
