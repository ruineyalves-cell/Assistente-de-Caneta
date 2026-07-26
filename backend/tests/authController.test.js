/**
 * Testes da lógica de segurança do authController (Lote H2):
 *   - Rotação de refresh token
 *   - Detecção de reuso (revoga família)
 *   - Refresh expirado / inválido
 *   - Lockout progressivo por email
 *
 * Estratégia: mocks manuais de db e userModel. Não usa dbMock (parser SQL
 * simplista quebraria em JOIN + INSERT com now()+interval). Aqui exercita
 * a máquina de decisão do controller — que é onde vive a segurança —
 * sem depender de nada em rede/disco.
 */

// Silencia logger nos testes (sem poluir output).
jest.mock('../src/utils/logger', () => ({
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
  logSeguranca: jest.fn(),
  capturarErro: jest.fn(),
}));

const mockQuery = jest.fn();
jest.mock('../src/config/db', () => ({ query: (...a) => mockQuery(...a) }));

const mockPorEmail = jest.fn();
jest.mock('../src/models/userModel', () => ({
  porEmail: (...a) => mockPorEmail(...a),
  criar: jest.fn(),
}));

process.env.JWT_SECRET = 'test-secret-for-unit-only';
process.env.REFRESH_EXPIRES_DAYS = '30';

// Precisa ser importado DEPOIS dos mocks pra que o require encontre o mock.
const auth = require('../src/controllers/authController');
const bcrypt = require('bcryptjs');

// Helper: cria res "espião" que registra .status().json() e resolve na hora.
function novoRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

// Helper: extrai o accessToken atrelado às chamadas de db pra inserção do refresh.
// Quando emitirRefresh() insere no db, params[0] é userId, params[1] é hash do token.
// Não conseguimos o token cleartext, mas conseguimos verificar que houve INSERT.

beforeEach(() => {
  mockQuery.mockReset();
  mockPorEmail.mockReset();
});

describe('/auth/refresh — rotação e reuso', () => {
  const userId = 'u-123';
  const role = 'paciente';
  const refreshToken = 'token-legitimo-nao-rotacionado';

  test('rota do refresh happy path — emite novo par + revoga antigo com replaced_by_id', async () => {
    // 1a query (SELECT do refresh corrente): devolve linha ATIVA
    // 2a query (INSERT novo refresh via emitirRefresh)
    // 3a query (SELECT id do novo pelo hash)
    // 4a query (UPDATE antigo com revoked_at + replaced_by_id)
    mockQuery
      .mockResolvedValueOnce({
        rows: [{
          id: 'rt-old',
          user_id: userId,
          revoked_at: null,
          expires_at: new Date(Date.now() + 30 * 86400 * 1000).toISOString(),
          role,
        }],
      })
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })       // INSERT novo
      .mockResolvedValueOnce({ rows: [{ id: 'rt-new' }] })    // SELECT id do novo
      .mockResolvedValueOnce({ rows: [], rowCount: 1 });      // UPDATE antigo

    const req = { body: { refreshToken } };
    const res = novoRes();
    await auth.refresh(req, res, jest.fn());

    expect(res.status).not.toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledTimes(1);
    const payload = res.json.mock.calls[0][0];
    expect(payload.accessToken).toEqual(expect.any(String));
    expect(payload.refreshToken).toEqual(expect.any(String));
    expect(payload.refreshToken).not.toBe(refreshToken); // rotação: novo ≠ antigo

    // A 4a chamada precisa ser o UPDATE do antigo com replaced_by_id apontando pro novo.
    const chamadas = mockQuery.mock.calls;
    const updateAntigo = chamadas[chamadas.length - 1];
    expect(updateAntigo[0]).toMatch(/UPDATE refresh_tokens SET revoked_at.*replaced_by_id/is);
    expect(updateAntigo[1]).toEqual(['rt-old', 'rt-new']);
  });

  test('reuso de refresh já rotacionado → 401 + revoga família inteira', async () => {
    // 1a query: token existe mas revoked_at != null (foi rotacionado antes)
    // 2a query: UPDATE em massa da família (todos refresh ativos do usuário)
    mockQuery
      .mockResolvedValueOnce({
        rows: [{
          id: 'rt-reused',
          user_id: userId,
          revoked_at: new Date().toISOString(), // ← chave da detecção
          expires_at: new Date(Date.now() + 30 * 86400 * 1000).toISOString(),
          role,
        }],
      })
      .mockResolvedValueOnce({ rows: [], rowCount: 3 }); // revogou 3 tokens da família

    const req = { body: { refreshToken } };
    const res = novoRes();
    await auth.refresh(req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(401);
    const payload = res.json.mock.calls[0][0];
    expect(payload.erro).toMatch(/reusado/i);
    // UPDATE em massa: WHERE user_id = $1 AND revoked_at IS NULL
    const updateMassa = mockQuery.mock.calls[1];
    expect(updateMassa[0]).toMatch(/UPDATE refresh_tokens SET revoked_at.*WHERE user_id.*revoked_at IS NULL/is);
    expect(updateMassa[1]).toEqual([userId]);
  });

  test('refresh expirado → 401 sem rotacionar nada', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{
        id: 'rt-old',
        user_id: userId,
        revoked_at: null,
        expires_at: new Date(Date.now() - 1000).toISOString(), // já venceu
        role,
      }],
    });

    const req = { body: { refreshToken } };
    const res = novoRes();
    await auth.refresh(req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json.mock.calls[0][0].erro).toMatch(/expirado/i);
    // Não deve ter havido INSERT/UPDATE
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  test('refresh inexistente → 401 sem tocar em nada', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });

    const req = { body: { refreshToken: 'token-que-nao-existe' } };
    const res = novoRes();
    await auth.refresh(req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json.mock.calls[0][0].erro).toMatch(/inválido/i);
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });
});

describe('/auth/login — lockout progressivo por email', () => {
  const email = 'ataque@example.com';
  const senhaCorreta = 'senhaForte123';
  const senhaErrada = 'chuteQualquer';

  beforeEach(async () => {
    // Cada teste: usuário existe com senhaCorreta bcrypt-hashed.
    const hash = await bcrypt.hash(senhaCorreta, 4); // rounds baixos: teste rápido
    mockPorEmail.mockResolvedValue({
      id: 'u-alvo',
      email,
      password_hash: hash,
      role: 'paciente',
      nome: 'Alvo',
    });
    // INSERT do refresh (só quando login tem sucesso)
    mockQuery.mockResolvedValue({ rows: [], rowCount: 1 });
  });

  test('5 falhas seguidas → 6ª tentativa devolve 429 mesmo com senha correta', async () => {
    for (let i = 0; i < 5; i++) {
      const res = novoRes();
      await auth.login(
        { body: { email, senha: senhaErrada } },
        res,
        jest.fn()
      );
      expect(res.status).toHaveBeenCalledWith(401);
    }

    // 6ª: senha CORRETA, mas ainda deve ser bloqueada (o lockout independe da senha)
    const res = novoRes();
    await auth.login(
      { body: { email, senha: senhaCorreta } },
      res,
      jest.fn()
    );
    expect(res.status).toHaveBeenCalledWith(429);
    expect(res.json.mock.calls[0][0].erro).toMatch(/tentativas|aguarde/i);
  });

  test('login bem-sucedido zera contador — próxima falha começa do zero', async () => {
    // 3 falhas
    for (let i = 0; i < 3; i++) {
      const res = novoRes();
      await auth.login({ body: { email: `${email}.reset`, senha: senhaErrada } }, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(401);
    }
    // Sucesso reseta
    {
      const res = novoRes();
      await auth.login({ body: { email: `${email}.reset`, senha: senhaCorreta } }, res, jest.fn());
      expect(res.status).not.toHaveBeenCalledWith(429);
    }
    // Mais 4 falhas (total pós-reset < 5) → ainda deveria deixar tentar
    for (let i = 0; i < 4; i++) {
      const res = novoRes();
      await auth.login({ body: { email: `${email}.reset`, senha: senhaErrada } }, res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(401);
    }
    // 5ª falha pós-reset → dispara lockout
    const res = novoRes();
    await auth.login({ body: { email: `${email}.reset`, senha: senhaErrada } }, res, jest.fn());
    // Aqui pode ser 401 (falha) OU 429 (locked) — depende de LOCK_APOS=5.
    // A 5ª falha registra a 5ª contagem, aí o handler atual retorna 401 pra
    // essa mesma request e bloqueia da 6ª em diante.
    expect(res.status).toHaveBeenCalledWith(401);

    const res6 = novoRes();
    await auth.login({ body: { email: `${email}.reset`, senha: senhaCorreta } }, res6, jest.fn());
    expect(res6.status).toHaveBeenCalledWith(429);
  });
});
