const { GoogleAuth } = require('google-auth-library');
const { logger, capturarErro } = require('./logger');

/**
 * Wrapper fino sobre Google Play Android Publisher API v3
 * (endpoint subscriptionsv2 — o "v3" refere-se à versão da API,
 * "v2" ao subrecurso mais moderno de assinaturas).
 *
 * Docs: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2
 *
 * Requer:
 *   - GOOGLE_PLAY_PACKAGE_NAME (ex.: br.com.recorpo.app)
 *   - GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (base64 do JSON da service account
 *     com role "Financial data / Manage orders and subscriptions" ligada
 *     no Play Console → Users and permissions).
 *
 * Ausência das envs = playApiConfigurada() === false — controller devolve
 * 503 sem quebrar o servidor.
 */

let _authCache = null;

function playApiConfigurada() {
  return !!(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON && packageName());
}

function packageName() {
  return process.env.GOOGLE_PLAY_PACKAGE_NAME || null;
}

function _getAuth() {
  if (_authCache) return _authCache;
  const b64 = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (!b64) return null;
  let credentials;
  try {
    credentials = JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
  } catch (err) {
    // Não expõe o valor no log — apenas o tipo do erro.
    logger.error({ err: err.message }, 'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON inválido');
    return null;
  }
  _authCache = new GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return _authCache;
}

/**
 * Consulta o estado atual de uma assinatura pelo purchaseToken.
 * Devolve payload normalizado, ou lança:
 *   - 'PLAY_API_NOT_CONFIGURED'   — envs ausentes
 *   - 'PURCHASE_TOKEN_NOT_FOUND'  — token nunca existiu (fraude ou expiry >60d)
 *   - 'PLAY_API_ERROR: <detalhe>' — qualquer outro erro
 */
async function obterAssinatura({ purchaseToken }) {
  const auth = _getAuth();
  const pkg = packageName();
  if (!auth || !pkg) {
    const err = new Error('PLAY_API_NOT_CONFIGURED');
    err.code = 'PLAY_API_NOT_CONFIGURED';
    throw err;
  }
  const client = await auth.getClient();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(pkg)}/purchases/subscriptionsv2/tokens/` +
    `${encodeURIComponent(purchaseToken)}`;
  try {
    const { data } = await client.request({ url });
    return _normalizar(data);
  } catch (err) {
    const status = err?.response?.status;
    if (status === 404 || status === 410) {
      const notFound = new Error('PURCHASE_TOKEN_NOT_FOUND');
      notFound.code = 'PURCHASE_TOKEN_NOT_FOUND';
      throw notFound;
    }
    capturarErro(err, { context: 'playApi.obterAssinatura', status });
    const generic = new Error(`PLAY_API_ERROR: ${err.message || 'unknown'}`);
    generic.code = 'PLAY_API_ERROR';
    throw generic;
  }
}

/**
 * Acknowledge é OBRIGATÓRIO em <=3 dias, senão o Play faz refund automático.
 * Idempotente do lado do Google: chamar 2x com token já acknowledged é no-op.
 */
async function acknowledgeAssinatura({ purchaseToken }) {
  const auth = _getAuth();
  const pkg = packageName();
  if (!auth || !pkg) {
    const err = new Error('PLAY_API_NOT_CONFIGURED');
    err.code = 'PLAY_API_NOT_CONFIGURED';
    throw err;
  }
  const client = await auth.getClient();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(pkg)}/purchases/subscriptionsv2/tokens/` +
    `${encodeURIComponent(purchaseToken)}:acknowledge`;
  await client.request({ url, method: 'POST', data: {} });
}

/**
 * Deriva o status simples que o app entende a partir do payload v2 do Play.
 * Mapeamento oficial: https://developers.google.com/android-publisher/subscriptions#lifecycle
 */
function _derivarStatus(raw) {
  switch (raw) {
    case 'SUBSCRIPTION_STATE_ACTIVE': return 'active';
    case 'SUBSCRIPTION_STATE_CANCELED': return 'canceled';
    case 'SUBSCRIPTION_STATE_EXPIRED': return 'expired';
    case 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD': return 'grace_period';
    case 'SUBSCRIPTION_STATE_ON_HOLD': return 'on_hold';
    case 'SUBSCRIPTION_STATE_PAUSED': return 'paused';
    case 'SUBSCRIPTION_STATE_PENDING': return 'pending';
    default: return 'expired'; // desconhecido = fail-closed (não libera Premium)
  }
}

function _normalizar(data) {
  const first = Array.isArray(data.lineItems) && data.lineItems.length > 0
    ? data.lineItems[0]
    : {};
  return {
    status: _derivarStatus(data.subscriptionState),
    productId: first.productId || null,
    expiryTime: first.expiryTime || null,
    autoRenewing: !!first.autoRenewingPlan?.autoRenewEnabled,
    acknowledged: data.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
    startTime: data.startTime || null,
    latestOrderId: data.latestOrderId || null,
    testPurchase: !!data.testPurchase,
    // Passa o raw pra logs de auditoria, mas não persiste em disco.
    _raw: data,
  };
}

/** Extrai userId embutido no `obfuscatedExternalAccountId` do purchase, se houver. */
function extrairUserIdDoRaw(raw) {
  return raw?.externalAccountIdentifiers?.obfuscatedExternalAccountId || null;
}

module.exports = {
  playApiConfigurada,
  obterAssinatura,
  acknowledgeAssinatura,
  extrairUserIdDoRaw,
  // Exportados para teste.
  _derivarStatus,
  _normalizar,
};
