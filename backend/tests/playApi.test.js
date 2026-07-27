/**
 * Unit tests dos helpers puros de playApi.js.
 * As chamadas HTTP não são testadas aqui (mockadas no subscriptionController.test.js).
 */
const { _derivarStatus, _normalizar } = require('../src/utils/playApi');

describe('_derivarStatus', () => {
  test.each([
    ['SUBSCRIPTION_STATE_ACTIVE', 'active'],
    ['SUBSCRIPTION_STATE_CANCELED', 'canceled'],
    ['SUBSCRIPTION_STATE_EXPIRED', 'expired'],
    ['SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'grace_period'],
    ['SUBSCRIPTION_STATE_ON_HOLD', 'on_hold'],
    ['SUBSCRIPTION_STATE_PAUSED', 'paused'],
    ['SUBSCRIPTION_STATE_PENDING', 'pending'],
  ])('%s → %s', (raw, esperado) => {
    expect(_derivarStatus(raw)).toBe(esperado);
  });

  test('estado desconhecido → expired (fail-closed)', () => {
    expect(_derivarStatus('SUBSCRIPTION_STATE_FUTURA_INVENTADA')).toBe('expired');
    expect(_derivarStatus(undefined)).toBe('expired');
    expect(_derivarStatus(null)).toBe('expired');
  });
});

describe('_normalizar', () => {
  test('payload v2 completo — extrai tudo do primeiro lineItem', () => {
    const raw = {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      startTime: '2026-01-01T00:00:00Z',
      latestOrderId: 'GPA.1234-5678',
      acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
      testPurchase: false,
      lineItems: [{
        productId: 'premium_mensal',
        expiryTime: '2026-02-01T00:00:00Z',
        autoRenewingPlan: { autoRenewEnabled: true },
      }],
    };
    const n = _normalizar(raw);
    expect(n.status).toBe('active');
    expect(n.productId).toBe('premium_mensal');
    expect(n.expiryTime).toBe('2026-02-01T00:00:00Z');
    expect(n.autoRenewing).toBe(true);
    expect(n.acknowledged).toBe(true);
    expect(n.latestOrderId).toBe('GPA.1234-5678');
    expect(n.startTime).toBe('2026-01-01T00:00:00Z');
    expect(n.testPurchase).toBe(false);
  });

  test('sem lineItems → productId/expiry null, mas status ainda deriva', () => {
    const raw = {
      subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
      lineItems: [],
    };
    const n = _normalizar(raw);
    expect(n.status).toBe('canceled');
    expect(n.productId).toBeNull();
    expect(n.expiryTime).toBeNull();
    expect(n.autoRenewing).toBe(false);
  });

  test('autoRenewingPlan ausente → autoRenewing false', () => {
    const raw = {
      subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
      lineItems: [{
        productId: 'premium_mensal',
        expiryTime: '2026-03-01T00:00:00Z',
      }],
    };
    const n = _normalizar(raw);
    expect(n.autoRenewing).toBe(false);
  });

  test('acknowledgementState pending → acknowledged false', () => {
    const raw = {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
      lineItems: [{ productId: 'x', expiryTime: '2026-01-01T00:00:00Z' }],
    };
    const n = _normalizar(raw);
    expect(n.acknowledged).toBe(false);
  });

  test('testPurchase true é preservado (útil pra QA)', () => {
    const raw = {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      testPurchase: true,
      lineItems: [{ productId: 'x', expiryTime: '2026-01-01T00:00:00Z' }],
    };
    const n = _normalizar(raw);
    expect(n.testPurchase).toBe(true);
  });
});
