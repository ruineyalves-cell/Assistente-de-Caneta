/**
 * Runner de migrations com LEDGER (Fase 2 auditoria de escalabilidade).
 *
 * Em vez de confiar em `IF NOT EXISTS` + tolerância a erro pra "adivinhar"
 * o que já rodou, registramos cada migration aplicada na tabela
 * `schema_migrations`. Assim:
 *   - migration já registrada → pulada sem re-executar (não dispara 42501
 *     nas ALTER antigas quando o role da app não é OWNER);
 *   - migration NOVA que falhe por 42501 → NÃO é registrada, continua
 *     visível/re-tentável e dispara alerta no Sentry (deixa de ser
 *     bomba-relógio silenciosa).
 *
 * Extraído de server.js pra ser injetável (db/logger/capturarAviso/dir) e
 * testável sem subir o servidor.
 */
const fs = require('node:fs');
const path = require('node:path');

/**
 * @param {object} deps
 * @param {{query: Function}} deps.db      façade de banco (config/db)
 * @param {object} deps.logger             pino logger
 * @param {Function} deps.capturarAviso    logger.capturarAviso (warn + Sentry)
 * @param {string} deps.dir                pasta das migrations *.sql
 */
async function aplicarMigrationsPendentes({ db, logger, capturarAviso, dir }) {
  if (!fs.existsSync(dir)) return;

  // Ledger criado AQUI (não como arquivo de migration) pra evitar
  // ovo-e-galinha: precisa existir antes de consultarmos o que já rodou.
  //
  // O role da app (ex.: appuser2) pode NÃO ter CREATE no schema public. E
  // `CREATE TABLE IF NOT EXISTS` ainda checa o privilégio de CREATE mesmo
  // quando a tabela já existe → 42501 que derrubaria o boot. Por isso
  // checamos a existência com to_regclass (um SELECT, que o role tem) e só
  // tentamos criar se realmente faltar (banco novo / rodando como owner).
  const { rows: ledgerRows } = await db.query(
    `SELECT to_regclass('public.schema_migrations') AS existe`
  );
  const ledgerJaExiste = ledgerRows[0] && ledgerRows[0].existe != null;
  if (!ledgerJaExiste) {
    await db.query(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
         filename   text PRIMARY KEY,
         applied_at timestamptz NOT NULL DEFAULT now()
       )`
    );
  }

  const arquivos = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  const { rows: registradas } = await db.query(`SELECT filename FROM schema_migrations`);
  const jaAplicadas = new Set(registradas.map((r) => r.filename));

  // BACKFILL (uma única vez): quando o ledger é introduzido num banco que
  // JÁ roda há tempos, ele está vazio, mas 001..00N já foram aplicadas em
  // deploys anteriores. Re-executá-las dispararia 42501 (ALTER sem OWNER)
  // e poluiria o Sentry. Heurística segura: o runner do boot só roda as
  // migrations (o schema base vem de schema.sql via `npm run db:migrate`),
  // então se a tabela base `users` existe, o schema estabelecido já passou
  // por todas as migrations atuais → marcamos todas como aplicadas SEM
  // executar. Banco novo (sem `users`) pula o backfill e roda tudo.
  if (jaAplicadas.size === 0) {
    const { rows: baseRows } = await db.query(`SELECT to_regclass('public.users') AS existe`);
    const schemaBaseExiste = baseRows[0] && baseRows[0].existe != null;
    if (schemaBaseExiste) {
      for (const f of arquivos) {
        await db.query(
          `INSERT INTO schema_migrations (filename) VALUES ($1) ON CONFLICT (filename) DO NOTHING`,
          [f]
        );
        jaAplicadas.add(f);
      }
      logger.info(
        { evento: 'migration_backfill', total: arquivos.length },
        'ledger de migrations inicializado (backfill do schema já existente)'
      );
    }
  }

  for (const f of arquivos) {
    if (jaAplicadas.has(f)) {
      logger.debug({ evento: 'migration_skip_ledger', arquivo: f }, `migration ${f} já no ledger`);
      continue;
    }
    try {
      await db.query(fs.readFileSync(path.join(dir, f), 'utf8'));
      await db.query(
        `INSERT INTO schema_migrations (filename) VALUES ($1) ON CONFLICT (filename) DO NOTHING`,
        [f]
      );
      logger.info({ evento: 'migration_ok', arquivo: f }, `migration ${f} aplicada`);
    } catch (err) {
      // 42501 = insufficient_privilege (role sem OWNER faz ALTER TABLE
      // devolver "must be owner"). NÃO registramos no ledger de propósito:
      // a migration continua re-tentável no próximo boot e o alerta abaixo
      // dispara toda vez até alguém rodar como owner. Uma migration NOVA
      // pulada aqui é bomba-relógio (rota quebra em runtime), então vai
      // pro Sentry via capturarAviso — nunca fica só no log.
      if (err && err.code === '42501') {
        capturarAviso(`migration ${f} ignorada por falta de OWNER`, {
          evento: 'migration_skip_permission',
          arquivo: f,
          msg: err.message,
          atencao:
            'NÃO registrada no ledger. Rode como owner (psql no Render Shell ou REASSIGN OWNED). Boot continua.',
        });
        continue;
      }
      logger.error({ evento: 'migration_falha', arquivo: f, err }, `migration ${f} falhou`);
      throw err;
    }
  }
}

module.exports = { aplicarMigrationsPendentes };
