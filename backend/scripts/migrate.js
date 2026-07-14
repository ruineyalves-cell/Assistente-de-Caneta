/** Aplica database/schema.sql e depois migrations/ em ordem alfabética. */
require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const { pool } = require('../src/config/db');

const DB_DIR = path.join(__dirname, '..', '..', 'database');

async function main() {
  const schema = fs.readFileSync(path.join(DB_DIR, 'schema.sql'), 'utf8');
  console.log('→ aplicando schema.sql ...');
  await pool.query(schema);

  const migDir = path.join(DB_DIR, 'migrations');
  const files = fs.readdirSync(migDir).filter((f) => f.endsWith('.sql')).sort();
  for (const f of files) {
    console.log(`→ aplicando migration ${f} ...`);
    await pool.query(fs.readFileSync(path.join(migDir, f), 'utf8'));
  }
  console.log('✅ banco migrado com sucesso');
  await pool.end();
}

main().catch((err) => { console.error('❌ migração falhou:', err.message); process.exit(1); });
