require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const app = require('./app');
const db = require('./config/db');

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
      console.log(`[migrations] ${f} aplicada`);
    } catch (err) {
      console.error(`[migrations] falha em ${f}:`, err.message);
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
      if (rowCount) console.log(`[lgpd] purga definitiva: ${rowCount} conta(s) eliminada(s)`);
    } catch (err) {
      console.error('[lgpd] falha na purga:', err.message);
    }
  }
  await purgarContasExpiradas();
  setInterval(purgarContasExpiradas, 12 * 3600 * 1000);

  app.listen(PORT, () => {
    console.log(`🚀 Assistente de Caneta API rodando em http://localhost:${PORT}`);
    console.log(`   Health check: http://localhost:${PORT}/health`);
  });
}

main().catch((err) => {
  console.error('Falha ao iniciar:', err);
  process.exit(1);
});
