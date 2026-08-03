/**
 * Testes do script de migração de CI (scripts/migrate-ledger.js).
 *
 * Cobrem só a lógica NOVA deste script (parse do FORCE + deleção do ledger
 * antes de re-aplicar). O runner em si (aplicarMigrationsPendentes) já é
 * coberto por migrator.test.js — aqui ele é injetado como spy.
 */
const { parseForceList, executarMigracaoCI } = require('../scripts/migrate-ledger');

const loggerNoop = { info() {}, warn() {}, error() {}, debug() {} };

describe('parseForceList', () => {
  test('vazio/undefined → lista vazia', () => {
    expect(parseForceList(undefined)).toEqual([]);
    expect(parseForceList('')).toEqual([]);
    expect(parseForceList('   ')).toEqual([]);
  });

  test('separa por vírgula, tira espaços e itens vazios', () => {
    expect(parseForceList('006_medications_2026.sql')).toEqual(['006_medications_2026.sql']);
    expect(parseForceList(' 006_a.sql , 007_b.sql ,, ')).toEqual(['006_a.sql', '007_b.sql']);
  });
});

/**
 * Fake db que registra as queries e simula o ledger para o DELETE do force.
 */
function fakeDb() {
  const queries = [];
  return {
    queries,
    async query(sql, params) {
      queries.push({ sql: String(sql).trim(), params });
      if (String(sql).includes('DELETE FROM schema_migrations')) {
        return { rows: [], rowCount: (params && params[0] ? params[0].length : 0) };
      }
      return { rows: [], rowCount: 0 };
    },
  };
}

describe('executarMigracaoCI', () => {
  test('SEM force: não mexe no ledger, só chama o runner', async () => {
    const db = fakeDb();
    const aplicar = jest.fn().mockResolvedValue(undefined);

    await executarMigracaoCI({
      db,
      logger: loggerNoop,
      capturarAviso: jest.fn(),
      dir: '/tmp/migrations',
      force: [],
      aplicar,
    });

    // Nenhum DELETE emitido.
    expect(db.queries.some((q) => q.sql.includes('DELETE FROM schema_migrations'))).toBe(false);
    expect(aplicar).toHaveBeenCalledTimes(1);
    expect(aplicar).toHaveBeenCalledWith(
      expect.objectContaining({ db, logger: loggerNoop, dir: '/tmp/migrations' })
    );
  });

  test('COM force: garante a tabela, deleta os arquivos do ledger e então aplica', async () => {
    const db = fakeDb();
    const aplicar = jest.fn().mockResolvedValue(undefined);

    await executarMigracaoCI({
      db,
      logger: loggerNoop,
      capturarAviso: jest.fn(),
      dir: '/tmp/migrations',
      force: ['006_medications_2026.sql'],
      aplicar,
    });

    const del = db.queries.find((q) => q.sql.includes('DELETE FROM schema_migrations'));
    expect(del).toBeDefined();
    expect(del.params).toEqual([['006_medications_2026.sql']]);

    // A tabela é garantida ANTES do delete (evita estourar em banco novo).
    const idxCreate = db.queries.findIndex((q) => q.sql.startsWith('CREATE TABLE IF NOT EXISTS schema_migrations'));
    const idxDelete = db.queries.findIndex((q) => q.sql.includes('DELETE FROM schema_migrations'));
    expect(idxCreate).toBeGreaterThanOrEqual(0);
    expect(idxCreate).toBeLessThan(idxDelete);

    // E o runner roda DEPOIS do reset.
    expect(aplicar).toHaveBeenCalledTimes(1);
  });
});
