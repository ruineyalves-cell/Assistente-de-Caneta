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
 *
 * Tolerância a permissão: quando trocamos o role da app (ex.: rotação
 * de credencial pra novo user com GRANT mas sem OWNER), ALTER TABLE
 * das migrations antigas passa a devolver 42501 "must be owner". Como
 * o schema alvo dessas migrations já existe (foi aplicado pelo owner
 * original), tratamos 42501 como no-op com WARN — o servidor continua
 * subindo. Erros de outra natureza continuam sendo fatais.
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
      // 42501 = insufficient_privilege.
      // Contexto: quando a app troca de role (rotação de credencial pra
      // novo user com GRANT mas sem OWNER), ALTER TABLE das migrations
      // antigas passa a devolver 42501. Como o schema alvo dessas
      // migrations JÁ EXISTE (foi aplicado pelo owner original), skip
      // com WARN — o servidor continua subindo em vez de crashar.
      //
      // ATENÇÃO: se a migration é NOVA (schema ainda não aplicado), esse
      // skip esconde o problema — o CREATE TABLE não vai rodar e a rota
      // que depende da tabela vai falhar em runtime com "relation does
      // not exist". A mensagem WARN abaixo é grep-able pra detectar isso
      // em logs. Fix definitivo: rodar a migration com role owner (via
      // psql direto no Render Shell ou fazendo REASSIGN OWNED).
      if (err && err.code === '42501') {
        logger.warn(
          {
            evento: 'migration_skip_permission',
            arquivo: f,
            msg: err.message,
            atencao: 'Se esta é uma migration NOVA, rode manualmente como owner. Boot continua.',
          },
          `migration ${f} ignorada por falta de OWNER`
        );
        continue;
      }
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
