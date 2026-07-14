/**
 * Config DB alternativa para desenvolvimento sem PostgreSQL/Docker
 * Usa SQLite em-memória (rápido, 0 dependências)
 * Quando PostgreSQL estiver pronto, mude DATABASE_URL para PostgreSQL
 */
const Database = require('better-sqlite3');
const fs = require('node:fs');

// Modo em-memória (rápido, reseta a cada restart)
const db = new (require('better-sqlite3'))(':memory:');

// Executa o schema SQL
const schema = fs.readFileSync(__dirname + '/../../database/schema.sql', 'utf8')
  .split(';')
  .filter(s => s.trim())
  .forEach(stmt => {
    try { db.exec(stmt); } catch (e) { console.warn('[schema]', e.message.slice(0, 60)); }
  });

// Interface compatível com pg (pool)
const pool = {
  query: (sql, params) => {
    try {
      const stmt = db.prepare(sql.replace(/\$(\d+)/g, '?'));
      const result = stmt.all(...(params || []));
      return Promise.resolve({ rows: result, rowCount: result.length });
    } catch (err) {
      console.error('[db] erro:', err.message);
      return Promise.reject(err);
    }
  },
  end: () => { db.close(); return Promise.resolve(); },
};

console.log('✅ SQLite em-memória carregado (desenvolvimento)');
console.log('⚠️  Dados resetam a cada restart. Para persistência: instale PostgreSQL e Docker.');

module.exports = { query: pool.query, pool };
