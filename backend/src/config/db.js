// Se NODE_ENV é 'development' e DATABASE_URL não foi definida, usa mock em-memória
// Caso contrário, usa PostgreSQL
let db;

if (process.env.NODE_ENV === 'development' && !process.env.DATABASE_URL) {
  console.log('[db] DATABASE_URL não configurada — usando Mock em-memória (dev only)');
  db = require('./dbMock');
} else {
  const { Pool } = require('pg');
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false,
    max: 10,
    idleTimeoutMillis: 30000,
  });
  pool.on('error', (err) => {
    console.error('[db] erro inesperado no pool:', err.message);
  });
  db = { query: (text, params) => pool.query(text, params), pool };
}

module.exports = db;
