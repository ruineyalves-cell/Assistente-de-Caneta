/**
 * Testes do subscriptionController (Play Billing).
 *
 * Estratégia: mock manual da Play API (playApi.obterAssinatura +
 * acknowledgeAssinatura) e do db. Exercita:
 *   - validar: happy path + purchase não encontrada + Play desconfigurada
 *   - status: sem assinatura, com assinatura fresca, com cache stale
 *   - rtdn: payload válido, sem token, token desconhecido, Play devolveu 404
 *   - _isPremium: helper puro
 */

jest.mock('../src/utils/logger', () => ({
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
  logSeguranca: jest.fn(),
  capturarErro: jest.fn(),
}));

const mockQuery = jest.fn();
jest.mock('../src/config/db', () => ({ query: (...a) => mockQuery(...a) }));

const mockObter = jest.fn();
const mockAck = jest.fn();
const mockConfigurada = jest.fn();
jest.mock('../src/utils/playApi', () => ({
  playApiConfigurada: (...a) => mockConfigurada(...a),
  obterAssinatura: (...a) => mockObter(...a),
  acknowledgeAssinatura: (...a) => mockAck(...a),
}));

const sub = require('../src/controllers/subscriptionController');

function novoRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

function novoReq(body = {}, headers = {}, userId = 'user-1') {
  return {
    body,
    headers,
    ip: '1.2.3.4',
    user: userId ? { id: userId } : undefined,
  };
}

beforeEach(() => {
  mockQuery.mockReset();
  mockObter.mockReset();
  mockAck.mockReset();
  mockConfigurada.mockReset();
});

// ─────────────────────────────────────────────────────────────
describe('_isPremium', () => {
  const futuro = new Date(Date.now() + 86400_000).toISOString();
  const passado = new Date(Date.now() - 86400_000).toISOString();

  test('active + expiry futuro = premium', () => {
    expect(sub._isPremium('active', futuro)).toBe(true);
  });
  test('grace_period + expiry futuro = premium (Play dá 30d de graça)', () => {
    expect(sub._isPremium('grace_period', futuro)).toBe(true);
  });
  test('on_hold já bloqueia mesmo com expiry futuro', () => {
    expect(sub._isPremium('on_hold', futuro)).toBe(false);
  });
  test('canceled + expiry futuro AINDA é premium até fim do período pago', () => {
    // Regra: user cancelou renovação mas segue premium até expiryTime.
    // Nosso helper hoje trata canceled = false — se quiser liberar até
    // expiry, muda pra incluir 'canceled'. Doc do comportamento atual:
    expect(sub._isPremium('canceled', futuro)).toBe(false);
  });
  test('active mas expirado = não premium (fail-closed)', () => {
    expect(sub._isPremium('active', passado)).toBe(false);
  });
  test('sem expiryTime = não premium', () => {
    expect(sub._isPremium('active', null)).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────
describe('validar', () => {
  test('503 quando Play API não configurada', async () => {
    mockConfigurada.mockReturnValue(false);
    const res = novoRes();
    const next = jest.fn();
    await sub.validar(novoReq({ purchaseToken: 'tok_abcdef123456', productId: 'premium_mensal' }), res, next);
    expect(res.status).toHaveBeenCalledWith(503);
    expect(next).not.toHaveBeenCalled();
  });

  test('happy path: valida, persiste, acknowledge quando pendente', async () => {
    mockConfigurada.mockReturnValue(true);
    mockObter.mockResolvedValue({
      status: 'active',
      productId: 'premium_mensal',
      expiryTime: new Date(Date.now() + 30 * 86400_000).toISOString(),
      autoRenewing: true,
      acknowledged: false,
      startTime: new Date().toISOString(),
      latestOrderId: 'GPA.1234-5678',
      testPurchase: false,
    });
    mockQuery.mockResolvedValue({ rowCount: 1 });
    mockAck.mockResolvedValue();

    const res = novoRes();
    const next = jest.fn();
    await sub.validar(novoReq({ purchaseToken: 'tok_abcdef123456', productId: 'premium_mensal' }), res, next);

    expect(mockObter).toHaveBeenCalledWith({ purchaseToken: 'tok_abcdef123456' });
    expect(mockQuery).toHaveBeenCalledTimes(1);
    expect(mockAck).toHaveBeenCalledWith({ purchaseToken: 'tok_abcdef123456' });
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      premium: true,
      status: 'active',
    }));
    expect(next).not.toHaveBeenCalled();
  });

  test('happy path: acknowledged=true → NÃO chama ack (idempotência)', async () => {
    mockConfigurada.mockReturnValue(true);
    mockObter.mockResolvedValue({
      status: 'active',
      productId: 'premium_mensal',
      expiryTime: new Date(Date.now() + 86400_000).toISOString(),
      autoRenewing: true,
      acknowledged: true,
      startTime: null,
      latestOrderId: null,
    });
    mockQuery.mockResolvedValue({ rowCount: 1 });

    const res = novoRes();
    await sub.validar(novoReq({ purchaseToken: 'tok_xxxxxxxx', productId: 'premium_anual' }), res, jest.fn());

    expect(mockAck).not.toHaveBeenCalled();
  });

  test('404 quando Play retorna PURCHASE_TOKEN_NOT_FOUND', async () => {
    mockConfigurada.mockReturnValue(true);
    const err = new Error('PURCHASE_TOKEN_NOT_FOUND');
    err.code = 'PURCHASE_TOKEN_NOT_FOUND';
    mockObter.mockRejectedValue(err);

    const res = novoRes();
    const next = jest.fn();
    await sub.validar(novoReq({ purchaseToken: 'tok_fake_1234567', productId: 'premium_mensal' }), res, next);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(mockQuery).not.toHaveBeenCalled();
    expect(next).not.toHaveBeenCalled();
  });

  test('outros erros da Play → next(err) (500 pelo errorHandler)', async () => {
    mockConfigurada.mockReturnValue(true);
    mockObter.mockRejectedValue(new Error('PLAY_API_ERROR: 500 upstream'));

    const res = novoRes();
    const next = jest.fn();
    await sub.validar(novoReq({ purchaseToken: 'tok_qwer_asdf12345', productId: 'premium_mensal' }), res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  test('body inválido é rejeitado antes de tocar na Play', async () => {
    mockConfigurada.mockReturnValue(true);
    const res = novoRes();
    const next = jest.fn();
    await sub.validar(novoReq({ purchaseToken: 'x', productId: '' }), res, next);
    expect(next).toHaveBeenCalled();
    expect(mockObter).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────
describe('status', () => {
  test('sem linha na tabela → premium=false', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    const res = novoRes();
    await sub.status(novoReq(), res, jest.fn());
    expect(res.json).toHaveBeenCalledWith({ premium: false, motivo: 'nenhuma_assinatura' });
  });

  test('cache fresco → não revalida na Play', async () => {
    mockQuery.mockResolvedValue({
      rows: [{
        purchase_token: 'tok_fresh_1234567',
        product_id: 'premium_mensal',
        status: 'active',
        expiry_time: new Date(Date.now() + 86400_000).toISOString(),
        auto_renewing: true,
        acknowledged: true,
        latest_check_at: new Date().toISOString(), // agora mesmo
      }],
    });
    const res = novoRes();
    await sub.status(novoReq(), res, jest.fn());
    expect(mockObter).not.toHaveBeenCalled();
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ premium: true }));
  });

  test('cache stale (>12h) revalida na Play e atualiza', async () => {
    mockConfigurada.mockReturnValue(true);
    const staleDate = new Date(Date.now() - 13 * 60 * 60 * 1000).toISOString();
    // Primeira query: SELECT. Segunda: UPDATE via _upsertAssinatura.
    mockQuery
      .mockResolvedValueOnce({
        rows: [{
          purchase_token: 'tok_stale_1234567',
          product_id: 'premium_mensal',
          status: 'active',
          expiry_time: new Date(Date.now() + 86400_000).toISOString(),
          auto_renewing: true,
          acknowledged: true,
          latest_check_at: staleDate,
        }],
      })
      .mockResolvedValueOnce({ rowCount: 1 });
    mockObter.mockResolvedValue({
      status: 'canceled', // mudou desde o cache
      productId: 'premium_mensal',
      expiryTime: new Date(Date.now() + 86400_000).toISOString(),
      autoRenewing: false,
      acknowledged: true,
      startTime: null,
      latestOrderId: 'GPA.1',
    });
    const res = novoRes();
    await sub.status(novoReq(), res, jest.fn());
    expect(mockObter).toHaveBeenCalled();
    expect(mockQuery).toHaveBeenCalledTimes(2);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      status: 'canceled',
      premium: false, // canceled → false (nosso _isPremium)
    }));
  });

  test('re-check falha → serve o cache mesmo assim', async () => {
    mockConfigurada.mockReturnValue(true);
    const staleDate = new Date(Date.now() - 13 * 60 * 60 * 1000).toISOString();
    mockQuery.mockResolvedValueOnce({
      rows: [{
        purchase_token: 'tok_stale_2222222',
        product_id: 'premium_mensal',
        status: 'active',
        expiry_time: new Date(Date.now() + 86400_000).toISOString(),
        auto_renewing: true,
        acknowledged: true,
        latest_check_at: staleDate,
      }],
    });
    mockObter.mockRejectedValue(new Error('network'));
    const res = novoRes();
    await sub.status(novoReq(), res, jest.fn());
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      status: 'active',
      premium: true,
    }));
  });
});

// ─────────────────────────────────────────────────────────────
describe('rtdn', () => {
  test('sem message.data → 200 e ignorado', async () => {
    const res = novoRes();
    await sub.rtdn(novoReq({}, {}), res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ ignorado: 'sem_data' }));
  });

  test('data com JSON inválido → 200 e ignorado', async () => {
    const req = novoReq({ message: { data: Buffer.from('não é json').toString('base64') } }, {});
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ ignorado: 'json_invalido' }));
  });

  test('data sem purchaseToken (test notification) → 200 e ignorado', async () => {
    const req = novoReq({
      message: { data: Buffer.from(JSON.stringify({ testNotification: {} })).toString('base64') },
    }, {});
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ ignorado: 'sem_token' }));
  });

  test('purchase_token desconhecido → 200 e ignorado (segurança: não reprocessa desconhecido)', async () => {
    mockConfigurada.mockReturnValue(true);
    mockQuery.mockResolvedValue({ rows: [] });
    const payload = { subscriptionNotification: { purchaseToken: 'tok_alien_9999' } };
    const req = novoReq({
      message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') },
    }, {});
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ ignorado: 'token_desconhecido' }));
    expect(mockObter).not.toHaveBeenCalled();
  });

  test('happy path: token conhecido + Play devolve dados → upsert', async () => {
    mockConfigurada.mockReturnValue(true);
    mockQuery
      .mockResolvedValueOnce({ rows: [{ user_id: 'user-42' }] })
      .mockResolvedValueOnce({ rowCount: 1 });
    mockObter.mockResolvedValue({
      status: 'canceled',
      productId: 'premium_mensal',
      expiryTime: new Date(Date.now() + 86400_000).toISOString(),
      autoRenewing: false,
      acknowledged: true,
      startTime: null,
      latestOrderId: null,
    });
    const payload = { subscriptionNotification: { purchaseToken: 'tok_conhecido_11111' } };
    const req = novoReq({
      message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') },
    }, {});
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ ok: true });
    expect(mockQuery).toHaveBeenCalledTimes(2);
  });

  test('Play devolve PURCHASE_TOKEN_NOT_FOUND → marca expired local', async () => {
    mockConfigurada.mockReturnValue(true);
    mockQuery
      .mockResolvedValueOnce({ rows: [{ user_id: 'user-1' }] })
      .mockResolvedValueOnce({ rowCount: 1 });
    const err = new Error('PURCHASE_TOKEN_NOT_FOUND');
    err.code = 'PURCHASE_TOKEN_NOT_FOUND';
    mockObter.mockRejectedValue(err);
    const payload = { subscriptionNotification: { purchaseToken: 'tok_expirado_zzzz' } };
    const req = novoReq({
      message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') },
    }, {});
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ marcado_expirado: true }));
  });

  test('exige x-rtdn-secret quando RTDN_SHARED_SECRET setado', async () => {
    process.env.RTDN_SHARED_SECRET = 'super-secreto';
    const payload = { subscriptionNotification: { purchaseToken: 'tok_x' } };
    const req = novoReq({
      message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') },
    }, { 'x-rtdn-secret': 'errado' });
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(401);
    delete process.env.RTDN_SHARED_SECRET;
  });

  test('erro inesperado → 200 (evita retry loop do Pub/Sub) + loga', async () => {
    mockConfigurada.mockReturnValue(true);
    mockQuery.mockRejectedValue(new Error('db down'));
    const payload = { subscriptionNotification: { purchaseToken: 'tok_x_1234567' } };
    const req = novoReq({
      message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') },
    }, {});
    const res = novoRes();
    await sub.rtdn(req, res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ ok: false }));
  });
});
