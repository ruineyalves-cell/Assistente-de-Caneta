require('dotenv').config();
const app = require('./app');
const db = require('./config/db');

const PORT = Number(process.env.PORT) || 3000;

async function main() {
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
