require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const app = require('./app');
const db = require('./config/db');
const { logger, capturarErro } = require('./utils/logger');

const PORT = Number(process.env.PORT) || 3000;

/**
 * Aplica database/migrations/*.sql em ordem alfabética. Idempotente —
 * todas as migrations devem usar IF NOT EXISTS. Roda na subida do
 * servidor pra evitar "precisa rodar npm run migrate manualmente no
 * Render" toda vez que uma coluna nova é adicionada.
 */
async function aplicarMigrationsPendentes() {
  const dir = path.join(__dirname, '..', '..', 'database', 'migrations');
  if (!fs.existsSync(dir)) return;
  const arquivos = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.sql'))
    .sort();
  for (const f of arquivos) {
    try {
      await db.query(fs.readFileSync(path.join(dir, f), 'utf8'));
      logger.info({ evento: 'migration_ok', arquivo: f }, `migration ${f} aplicada`);
    } catch (err) {
      logger.error({ evento: 'migration_falha', arquivo: f, err }, `migration ${f} falhou`);
      throw err;
    }
  }
}

async function main() {
  await aplicarMigrationsPendentes();


  // Job de purga LGPD: elimina definitivamente contas com purge_after vencido.
  // Roda na subida e a cada 12h (em produção considerar cron do Railway).
  async function purgarContasExpiradas() {
    try {
      const { rowCount } = await db.query(
        `DELETE FROM users WHERE deleted_at IS NOT NULL AND purge_after < now()`
      );
      if (rowCount) {
        logger.info({ evento: 'lgpd_purga', contas: rowCount }, 'purga LGPD executada');
      }
    } catch (err) {
      capturarErro(err, { onde: 'lgpd_purga' });
    }
  }
  await purgarContasExpiradas();
  setInterval(purgarContasExpiradas, 12 * 3600 * 1000);

  app.listen(PORT, () => {
    logger.info({ porta: PORT }, 'Recorpo API rodando');
  });
}

// Errors não capturados no event loop → Sentry + log estruturado.
process.on('uncaughtException', (err) => capturarErro(err, { onde: 'uncaughtException' }));
process.on('unhandledRejection', (err) => capturarErro(err, { onde: 'unhandledRejection' }));

main().catch((err) => {
  capturarErro(err, { onde: 'main' });
  process.exit(1);
});
