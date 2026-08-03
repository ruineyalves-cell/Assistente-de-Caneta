/**
 * Aplica migrations PENDENTES via ledger (schema_migrations), reusando o
 * runner idempotente da Fase 2 (src/config/migrator.js). Feito para rodar no
 * CI (.github/workflows/migrate-postgres.yml) com a conexão OWNER do Postgres.
 *
 * Por que existe (vs. scripts/migrate.js legado):
 *   - migrate.js reaplica schema.sql + TODAS as migrations direto (sem
 *     ledger) — bom pra criar um banco do zero, ruim pra produção
 *     estabelecida (re-roda ALTER antigas).
 *   - este roda o MESMO código do boot (aplicarMigrationsPendentes), que
 *     respeita o ledger e só aplica o que falta. A diferença é a CREDENCIAL:
 *     aqui o DATABASE_URL é a conexão owner (secret no CI), então migrations
 *     que o role limitado da app não consegue aplicar (42501) passam.
 *
 * FORCE_MIGRATIONS (env, opcional): lista separada por vírgula de arquivos a
 * re-aplicar mesmo já estando no ledger. Remove-os do ledger ANTES de rodar,
 * pra o migrator os enxergar como pendentes. Use SÓ com migrations idempotentes
 * (ex.: 006_medications_2026.sql é INSERT ... WHERE NOT EXISTS). Serve pra
 * destravar uma migration que ficou marcada como aplicada sem ter rodado de
 * fato (ex.: backfill do ledger num deploy onde o arquivo já existia).
 *
 * Uso local (NÃO aponte pra produção sem querer):
 *   DATABASE_URL=<owner> PGSSL=true node scripts/migrate-ledger.js
 *   FORCE_MIGRATIONS=006_medications_2026.sql DATABASE_URL=<owner> PGSSL=true \
 *     node scripts/migrate-ledger.js
 */
require('dotenv').config();
const path = require('node:path');

const MIGRATIONS_DIR = path.join(__dirname, '..', '..', 'database', 'migrations');

/**
 * Normaliza a env FORCE_MIGRATIONS numa lista limpa de nomes de arquivo.
 * Pura (sem I/O) pra ser testável.
 * @param {string|undefined} raw
 * @returns {string[]}
 */
function parseForceList(raw) {
  if (!raw) return [];
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

/**
 * Remove do ledger os arquivos forçados (se houver) e aplica as pendentes.
 * Injetável (db/logger/capturarAviso/dir/force) pra ser testável sem Postgres.
 *
 * @param {object}   deps
 * @param {{query: Function}} deps.db
 * @param {object}   deps.logger
 * @param {Function} deps.capturarAviso
 * @param {string}   deps.dir
 * @param {string[]} [deps.force]  arquivos a re-aplicar (removidos do ledger antes)
 * @param {Function} deps.aplicar  runner de migrations (injetável p/ teste)
 */
async function executarMigracaoCI({ db, logger, capturarAviso, dir, force = [], aplicar }) {
  if (force.length > 0) {
    // A tabela pode não existir ainda num banco novo; o migrator a cria. Aqui
    // garantimos a existência antes do DELETE pra não estourar em banco novo.
    await db.query(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
         filename   text PRIMARY KEY,
         applied_at timestamptz NOT NULL DEFAULT now()
       )`
    );
    const { rowCount } = await db.query(
      `DELETE FROM schema_migrations WHERE filename = ANY($1::text[])`,
      [force]
    );
    logger.info(
      { evento: 'migration_force_reset', arquivos: force, removidos: rowCount },
      `force: ${rowCount} registro(s) removido(s) do ledger → serão re-aplicados`
    );
  }

  await aplicar({ db, logger, capturarAviso, dir });
}

async function main() {
  const { logger, capturarAviso } = require('../src/utils/logger');

  if (!process.env.DATABASE_URL) {
    logger.error(
      { evento: 'migrate_ci_sem_url' },
      'DATABASE_URL ausente — este script exige a conexão OWNER do Postgres'
    );
    process.exit(1);
  }

  const db = require('../src/config/db');
  const { aplicarMigrationsPendentes } = require('../src/config/migrator');
  const force = parseForceList(process.env.FORCE_MIGRATIONS);

  // Snapshot do ledger antes (auditoria no log do CI; nada sensível).
  try {
    const { rows } = await db.query(
      `SELECT filename FROM schema_migrations ORDER BY filename`
    );
    logger.info(
      { evento: 'migrate_ci_ledger_antes', total: rows.length, arquivos: rows.map((r) => r.filename) },
      'ledger antes de aplicar'
    );
  } catch {
    logger.info({ evento: 'migrate_ci_ledger_antes' }, 'ledger ainda não existe (banco novo)');
  }

  try {
    await executarMigracaoCI({
      db,
      logger,
      capturarAviso,
      dir: MIGRATIONS_DIR,
      force,
      aplicar: aplicarMigrationsPendentes,
    });

    const { rows } = await db.query(
      `SELECT filename FROM schema_migrations ORDER BY filename`
    );
    logger.info(
      { evento: 'migrate_ci_ok', total: rows.length, arquivos: rows.map((r) => r.filename) },
      'migrations pendentes aplicadas (ou nada a fazer)'
    );
  } catch (err) {
    logger.error({ evento: 'migrate_ci_falha', err }, 'falha ao aplicar migrations');
    process.exitCode = 1;
  } finally {
    if (db.pool && typeof db.pool.end === 'function') {
      await db.pool.end().catch(() => {});
    }
  }
}

// Só executa quando chamado direto (node scripts/migrate-ledger.js), não quando
// importado por um teste.
if (require.main === module) {
  main();
}

module.exports = { parseForceList, executarMigracaoCI };
