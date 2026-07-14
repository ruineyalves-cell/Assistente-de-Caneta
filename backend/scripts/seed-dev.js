/**
 * Seed para desenvolvimento (SQLite em-memória)
 * Populando medicações + usuário de teste
 */
require('dotenv').config({ path: __dirname + '/../.env.development' });
const db = require('../src/config/db');
const bcrypt = require('bcryptjs');
const fs = require('node:fs');

async function seed() {
  console.log('🌱 Seed de desenvolvimento...\n');

  // 1. Medicações (mesmo SQL do seed principal)
  const med = fs.readFileSync(__dirname + '/../../database/seeds/001_medications.sql', 'utf8');
  try {
    await db.query(med);
    console.log('✅ Medicações inseridas');
  } catch (e) {
    console.log('ℹ️  Medicações já existem:', e.message.slice(0, 50));
  }

  // 2. Usuário de teste (paciente)
  const hash = await bcrypt.hash('Senha123!', 12);
  try {
    await db.query(
      `INSERT INTO users (id, email, password_hash, role, nome, data_nascimento, created_at)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, now())`,
      ['maria@test.com', hash, 'paciente', 'Maria Silva', '1990-05-10']
    );
    console.log('✅ Usuário de teste criado: maria@test.com / Senha123!');
  } catch (e) {
    console.log('ℹ️  Usuário já existe');
  }

  // 3. Usuário de teste (profissional)
  const hashProf = await bcrypt.hash('DocSenha123!', 12);
  try {
    await db.query(
      `INSERT INTO users (id, email, password_hash, role, nome, data_nascimento, created_at)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, now())`,
      ['dr.carlos@test.com', hashProf, 'profissional', 'Dr. Carlos', '1980-03-15']
    );
    console.log('✅ Profissional de teste criado: dr.carlos@test.com / DocSenha123!');
  } catch (e) {
    console.log('ℹ️  Profissional já existe');
  }

  console.log('\n💡 Pronto para testar! Endpoints de teste:');
  console.log('   POST /api/auth/login { email: "maria@test.com", senha: "Senha123!" }');
  console.log('   GET /api/medicacoes');
  console.log('   GET /api/health\n');
  process.exit(0);
}

seed().catch(e => { console.error(e); process.exit(1); });
