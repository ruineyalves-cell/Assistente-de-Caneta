/** Aplica database/seeds/ em ordem alfabética (idempotente por design dos seeds). */
require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const { pool } = require('../src/config/db');

const SEED_DIR = path.join(__dirname, '..', '..', 'database', 'seeds');

async function main() {
  // evita duplicar catálogo se já semeado
  const { rows } = await pool.query(`SELECT count(*)::int AS n FROM medications`);
  if (rows[0].n > 0) {
    console.log(`ℹ️ medications já tem ${rows[0].n} registros — seed pulado (limpe a tabela para re-seed).`);
    await pool.end();
    return;
  }
  const files = fs.readdirSync(SEED_DIR).filter((f) => f.endsWith('.sql')).sort();
  for (const f of files) {
    console.log(`→ aplicando seed ${f} ...`);
    await pool.query(fs.readFileSync(path.join(SEED_DIR, f), 'utf8'));
  }
  console.log('✅ seeds aplicados');
  await pool.end();
}

main().catch((err) => { console.error('❌ seed falhou:', err.message); process.exit(1); });
