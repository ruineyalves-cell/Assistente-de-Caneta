/**
 * Testes do runner de migrations com ledger (config/migrator.js).
 *
 * Usa um fake db em-memória e uma pasta temporária de migrations, pra
 * exercitar o comportamento sem Postgres nem subir o servidor.
 */
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { aplicarMigrationsPendentes } = require('../src/config/migrator');

const loggerNoop = { info() {}, warn() {}, error() {}, debug() {} };

/**
 * Fake db. Cada arquivo .sql de teste carrega um marcador `-- FILE:<nome>`
 * na primeira linha pra o fake saber qual migration está executando.
 *
 * @param usersExists  simula existência da tabela base `users`
 * @param failOn       { 'arquivo.sql': codigoErro } — lança ao executar o corpo
 */
function fakeDb({ usersExists = true, failOn = {} } = {}) {
  const applied = new Set();
  const executed = [];
  return {
    applied,
    executed,
    async query(sql, params) {
      const s = String(sql).trim();
      if (s.startsWith('CREATE TABLE IF NOT EXISTS schema_migrations')) {
        return { rows: [], rowCount: 0 };
      }
      if (s.startsWith('SELECT filename FROM schema_migrations')) {
        return { rows: [...applied].map((f) => ({ filename: f })), rowCount: applied.size };
      }
      if (s.includes("to_regclass('public.users')")) {
        return { rows: [{ existe: usersExists ? 'users' : null }], rowCount: 1 };
      }
      if (s.startsWith('INSERT INTO schema_migrations')) {
        applied.add(params[0]);
        return { rows: [], rowCount: 1 };
      }
      // Corpo de uma migration (conteúdo do arquivo).
      const m = s.match(/-- FILE:(\S+)/);
      const file = m ? m[1] : null;
      if (file && failOn[file]) {
        const err = new Error(`erro simulado em ${file}`);
        err.code = failOn[file];
        throw err;
      }
      if (file) executed.push(file);
      return { rows: [], rowCount: 0 };
    },
  };
}

let dir;
beforeEach(() => {
  dir = fs.mkdtempSync(path.join(os.tmpdir(), 'migrator-'));
  fs.writeFileSync(path.join(dir, '001_a.sql'), '-- FILE:001_a.sql\nSELECT 1;');
  fs.writeFileSync(path.join(dir, '002_b.sql'), '-- FILE:002_b.sql\nSELECT 2;');
});
afterEach(() => {
  fs.rmSync(dir, { recursive: true, force: true });
});

test('banco NOVO (sem users, ledger vazio): roda tudo e registra tudo', async () => {
  const db = fakeDb({ usersExists: false });
  const aviso = jest.fn();
  await aplicarMigrationsPendentes({ db, logger: loggerNoop, capturarAviso: aviso, dir });

  expect(db.executed).toEqual(['001_a.sql', '002_b.sql']);
  expect([...db.applied].sort()).toEqual(['001_a.sql', '002_b.sql']);
  expect(aviso).not.toHaveBeenCalled();
});

test('banco ESTABELECIDO (users existe, ledger vazio): backfill sem executar', async () => {
  const db = fakeDb({ usersExists: true });
  const aviso = jest.fn();
  await aplicarMigrationsPendentes({ db, logger: loggerNoop, capturarAviso: aviso, dir });

  // Nada executado (evita 42501 nas ALTER antigas), mas tudo registrado.
  expect(db.executed).toEqual([]);
  expect([...db.applied].sort()).toEqual(['001_a.sql', '002_b.sql']);
  expect(aviso).not.toHaveBeenCalled();
});

test('boot SEGUINTE (ledger já tem tudo): não re-executa nada', async () => {
  const db = fakeDb({ usersExists: true });
  db.applied.add('001_a.sql');
  db.applied.add('002_b.sql');
  const aviso = jest.fn();
  await aplicarMigrationsPendentes({ db, logger: loggerNoop, capturarAviso: aviso, dir });

  expect(db.executed).toEqual([]);
  expect(aviso).not.toHaveBeenCalled();
});

test('migration NOVA falha por 42501: alerta e NÃO registra (fica re-tentável)', async () => {
  // Ledger já tem 001 → sem backfill; 002 é nova e falha por permissão.
  const db = fakeDb({ usersExists: true, failOn: { '002_b.sql': '42501' } });
  db.applied.add('001_a.sql');
  const aviso = jest.fn();
  await aplicarMigrationsPendentes({ db, logger: loggerNoop, capturarAviso: aviso, dir });

  expect(db.executed).toEqual([]); // 001 pulada (ledger), 002 lançou antes de registrar
  expect(db.applied.has('002_b.sql')).toBe(false); // não registrada → re-tentável
  expect(aviso).toHaveBeenCalledTimes(1);
  expect(aviso.mock.calls[0][0]).toMatch(/002_b\.sql/);
  expect(aviso.mock.calls[0][1].evento).toBe('migration_skip_permission');
});

test('erro NÃO-42501 é fatal (propaga)', async () => {
  const db = fakeDb({ usersExists: true, failOn: { '002_b.sql': '42P01' } });
  db.applied.add('001_a.sql');
  const aviso = jest.fn();
  await expect(
    aplicarMigrationsPendentes({ db, logger: loggerNoop, capturarAviso: aviso, dir })
  ).rejects.toThrow(/erro simulado/);
  expect(aviso).not.toHaveBeenCalled();
});
