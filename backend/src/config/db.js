/**
 * Camada de acesso a Postgres — preparada pra escalar horizontalmente.
 *
 * Exporta 3 façades:
 *   - `db`        → alias compatível com código legado (writes por padrão)
 *   - `dbWrite`   → sempre master (INSERT/UPDATE/DELETE, transações)
 *   - `dbRead`    → réplica de leitura se DATABASE_READ_URL estiver
 *                   setada; senão cai no master (comportamento MVP)
 *
 * Quando um dia sair do Render Free/Starter pra Standard com read
 * replica, basta setar `DATABASE_READ_URL` no ambiente — nenhuma
 * refatoração de código.
 *
 * SEGURANÇA (F3):
 *   - `PGSSL=true`  → força TLS aceitando cert self-signed do Render (ok
 *     porque a rede interna do Render é isolada; Postgres público seria
 *     PGSSLROOTCERT com CA custom).
 *   - Sem PGSSL     → deixamos ssl `undefined`, o que faz o pg lib
 *     PARSEAR `sslmode=` da URL. Nossa DATABASE_URL termina com
 *     `?sslmode=require`, então TLS fica ligado por padrão. Antes usávamos
 *     `ssl:false` explícito, que SOBRESCREVIA o sslmode= e conectaria em
 *     plaintext se um dia mudarmos de provider (Render força TLS
 *     server-side, então nunca quebrou em prod — mas ficava frágil).
 */
let db, dbRead, dbWrite;

if (process.env.NODE_ENV === 'development' && !process.env.DATABASE_URL) {
  console.log('[db] DATABASE_URL não configurada — usando Mock em-memória (dev only)');
  db = require('./dbMock');
  dbRead = db;
  dbWrite = db;
} else {
  const { Pool } = require('pg');

  function novoPool(url, tag) {
    const pool = new Pool({
      connectionString: url,
      ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : undefined,
      // max=5 é seguro pro Render Starter (limite de 97 conexões) mesmo
      // com múltiplas instâncias no futuro. Idle 30s libera pra outras
      // requests não ficarem esperando.
      max: Number(process.env.PG_POOL_MAX) || 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    });
    pool.on('error', (err) => {
      console.error(`[db:${tag}] erro inesperado no pool:`, err.message);
    });
    return pool;
  }

  const poolWrite = novoPool(process.env.DATABASE_URL, 'write');
  const poolRead = process.env.DATABASE_READ_URL
    ? novoPool(process.env.DATABASE_READ_URL, 'read')
    : poolWrite;

  dbWrite = { query: (t, p) => poolWrite.query(t, p), pool: poolWrite };
  dbRead = { query: (t, p) => poolRead.query(t, p), pool: poolRead };
  db = dbWrite; // legacy alias
}

module.exports = db;
module.exports.dbRead = dbRead;
module.exports.dbWrite = dbWrite;
