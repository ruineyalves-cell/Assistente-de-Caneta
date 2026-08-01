require('dotenv').config();
const path = require('node:path');
const app = require('./app');
const db = require('./config/db');
const { logger, capturarErro, capturarAviso } = require('./utils/logger');
const { aplicarMigrationsPendentes } = require('./config/migrator');

const PORT = Number(process.env.PORT) || 3000;

// Pasta das migrations, resolvida a partir da raiz do repo.
const MIGRATIONS_DIR = path.join(__dirname, '..', '..', 'database', 'migrations');

async function main() {
  await aplicarMigrationsPendentes({ db, logger, capturarAviso, dir: MIGRATIONS_DIR });


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
