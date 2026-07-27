/**
 * Assinatura Premium via Google Play Billing.
 *
 * Fluxo:
 *   1) App faz purchase via BillingClient (Play Billing Library).
 *   2) App envia POST /api/assinaturas/validar com o purchaseToken.
 *   3) Backend consulta a Play API pra confirmar (fonte de verdade),
 *      persiste em `subscriptions`, faz acknowledge.
 *   4) App consulta GET /api/assinaturas/status pra saber se Premium
 *      continua ativo (com fallback re-check via API se cache >12h).
 *   5) Play dispara RTDN (Real-Time Developer Notifications) via Pub/Sub
 *      quando algo muda; POST /api/assinaturas/rtdn reprocessa.
 *
 * Segurança:
 *   - Purchase token é confidencial: usado como capability. Nunca logamos.
 *   - Só o dono pode consultar `status` do próprio user.
 *   - Webhook RTDN valida pelo purchase_token (sem trust no payload).
 */

const { z } = require('zod');
const db = require('../config/db');
const {
  playApiConfigurada,
  obterAssinatura,
  acknowledgeAssinatura,
} = require('../utils/playApi');
const { logger, capturarErro } = require('../utils/logger');

const validarSchema = z.object({
  purchaseToken: z.string().min(10).max(1000),
  productId: z.string().min(1).max(120),
});

/**
 * POST /api/assinaturas/validar
 * Verifica com o Google Play, persiste, acknowledge.
 */
async function validar(req, res, next) {
  try {
    const { purchaseToken, productId } = validarSchema.parse(req.body);
    if (!playApiConfigurada()) {
      return res.status(503).json({
        erro: 'Assinaturas ainda não configuradas no servidor.',
      });
    }

    let info;
    try {
      info = await obterAssinatura({ purchaseToken });
    } catch (err) {
      if (err.code === 'PURCHASE_TOKEN_NOT_FOUND') {
        return res.status(404).json({
          erro: 'Compra não reconhecida pelo Google Play. Se acabou de assinar, aguarde alguns segundos e tente novamente.',
        });
      }
      throw err;
    }

    // Sanity: productId enviado precisa bater com o retornado pela Play API.
    // Isso protege contra o cliente enviar um SKU errado (não é ataque, mas
    // ajuda a detectar bug no app cedo).
    if (info.productId && info.productId !== productId) {
      logger.warn({
        userId: req.user.id,
        productIdEnviado: productId,
        productIdReal: info.productId,
      }, 'productId divergente do Play — usando o do Play');
    }

    await _upsertAssinatura({
      userId: req.user.id,
      purchaseToken,
      info,
    });

    // Acknowledge se ainda não estiver — obrigação do Google, evita refund
    // automático após 3 dias. Idempotente (chamar 2x = no-op).
    if (!info.acknowledged && info.status === 'active') {
      try {
        await acknowledgeAssinatura({ purchaseToken });
      } catch (err) {
        // Não bloqueia a resposta ao app — se o ack falhar por rede,
        // o webhook RTDN ou o próximo /status vai reprocessar.
        capturarErro(err, { context: 'subscription.acknowledge', userId: req.user.id });
      }
    }

    return res.json(_serializar(info));
  } catch (err) { next(err); }
}

/**
 * GET /api/assinaturas/status
 * Devolve estado atual do usuário. Se cache >12h, revalida no Play.
 */
async function status(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT purchase_token, product_id, status, expiry_time, auto_renewing,
              acknowledged, latest_check_at
         FROM subscriptions
        WHERE user_id = $1
        ORDER BY expiry_time DESC NULLS LAST
        LIMIT 1`,
      [req.user.id]
    );
    if (rows.length === 0) {
      return res.json({ premium: false, motivo: 'nenhuma_assinatura' });
    }
    let row = rows[0];

    // Cache stale? Revalida no Play se possível.
    const staleMs = 12 * 60 * 60 * 1000; // 12h
    const stale = Date.now() - new Date(row.latest_check_at).getTime() > staleMs;
    if (stale && playApiConfigurada()) {
      try {
        const info = await obterAssinatura({ purchaseToken: row.purchase_token });
        await _upsertAssinatura({
          userId: req.user.id,
          purchaseToken: row.purchase_token,
          info,
        });
        row = {
          ...row,
          product_id: info.productId || row.product_id,
          status: info.status,
          expiry_time: info.expiryTime,
          auto_renewing: info.autoRenewing,
          acknowledged: info.acknowledged,
          latest_check_at: new Date(),
        };
      } catch (err) {
        // Se falhou re-check, servimos o cache mesmo — melhor que 500.
        capturarErro(err, { context: 'subscription.status.recheck', userId: req.user.id });
      }
    }

    return res.json({
      premium: _isPremium(row.status, row.expiry_time),
      productId: row.product_id,
      status: row.status,
      expiryTime: row.expiry_time,
      autoRenewing: row.auto_renewing,
    });
  } catch (err) { next(err); }
}

/**
 * POST /api/assinaturas/rtdn
 * Recebe Real-Time Developer Notifications do Google Play via Pub/Sub push.
 *
 * Payload padrão do Pub/Sub push:
 *   {
 *     message: { data: <base64 JSON>, messageId, publishTime },
 *     subscription: "projects/xxx/subscriptions/yyy"
 *   }
 *
 * O JSON decodado tem `subscriptionNotification.purchaseToken`. NÃO
 * confiamos em nenhum campo dele — só usamos o token pra reconsultar
 * a Play API (que é a fonte de verdade).
 *
 * Segurança: idealmente o Pub/Sub deve ter push authentication (OIDC
 * token). Aceitamos qualquer POST, mas SEMPRE reconsultamos a Play —
 * um atacante disparando o webhook só consegue gastar chamadas da API,
 * não alterar dados. Se `RTDN_SHARED_SECRET` estiver setada, exigimos
 * também no header `x-rtdn-secret`.
 */
async function rtdn(req, res, next) {
  try {
    const expectedSecret = process.env.RTDN_SHARED_SECRET;
    if (expectedSecret) {
      const got = req.headers['x-rtdn-secret'];
      if (got !== expectedSecret) {
        return res.status(401).json({ erro: 'unauthorized' });
      }
    }

    const pubsub = req.body?.message;
    if (!pubsub?.data) {
      // Pub/Sub sempre manda algo — se veio vazio, é health-check
      // ou payload corrompido; ACK com 200 pra não gerar retry loop.
      return res.status(200).json({ ok: true, ignorado: 'sem_data' });
    }

    let payload;
    try {
      payload = JSON.parse(Buffer.from(pubsub.data, 'base64').toString('utf8'));
    } catch (err) {
      logger.warn({ err: err.message }, 'RTDN payload não é JSON válido');
      return res.status(200).json({ ok: true, ignorado: 'json_invalido' });
    }

    const purchaseToken =
      payload?.subscriptionNotification?.purchaseToken ||
      payload?.voidedPurchaseNotification?.purchaseToken;
    if (!purchaseToken) {
      // Test notifications não têm purchaseToken — ACK e ignora.
      return res.status(200).json({ ok: true, ignorado: 'sem_token' });
    }

    if (!playApiConfigurada()) {
      // Play API desligada = não sabemos revalidar; ACK pra Pub/Sub
      // não fazer retry infinito, mas loga.
      logger.warn({ purchaseToken: '[redacted]' }, 'RTDN recebido mas Play API não configurada');
      return res.status(200).json({ ok: true, ignorado: 'play_desconfigurada' });
    }

    // Recupera userId da linha existente (o app já validou uma vez).
    const { rows } = await db.query(
      `SELECT user_id FROM subscriptions WHERE purchase_token = $1`,
      [purchaseToken]
    );
    if (rows.length === 0) {
      logger.warn('RTDN pra purchase_token desconhecido — ignorado');
      return res.status(200).json({ ok: true, ignorado: 'token_desconhecido' });
    }
    const userId = rows[0].user_id;

    let info;
    try {
      info = await obterAssinatura({ purchaseToken });
    } catch (err) {
      if (err.code === 'PURCHASE_TOKEN_NOT_FOUND') {
        // Play descartou o token — marca como expired local.
        await db.query(
          `UPDATE subscriptions SET status = 'expired', latest_check_at = now(), updated_at = now()
             WHERE purchase_token = $1`,
          [purchaseToken]
        );
        return res.status(200).json({ ok: true, marcado_expirado: true });
      }
      throw err;
    }

    await _upsertAssinatura({ userId, purchaseToken, info });
    return res.status(200).json({ ok: true });
  } catch (err) {
    // RTDN em erro NÃO deve dar 500 — Pub/Sub faria retry agressivo.
    // Loga, retorna 200 e o próximo /status vai reconciliar.
    capturarErro(err, { context: 'subscription.rtdn' });
    return res.status(200).json({ ok: false, erro: 'processing_error' });
  }
}

// ─────────────────────────────────────────────────────────────

async function _upsertAssinatura({ userId, purchaseToken, info }) {
  await db.query(
    `INSERT INTO subscriptions
       (user_id, purchase_token, product_id, order_id, status,
        expiry_time, auto_renewing, acknowledged, start_time, latest_check_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9, now())
     ON CONFLICT (purchase_token) DO UPDATE SET
       status = EXCLUDED.status,
       expiry_time = EXCLUDED.expiry_time,
       auto_renewing = EXCLUDED.auto_renewing,
       acknowledged = EXCLUDED.acknowledged,
       order_id = COALESCE(EXCLUDED.order_id, subscriptions.order_id),
       product_id = COALESCE(EXCLUDED.product_id, subscriptions.product_id),
       latest_check_at = now(),
       updated_at = now()`,
    [
      userId,
      purchaseToken,
      info.productId,
      info.latestOrderId,
      info.status,
      info.expiryTime,
      info.autoRenewing,
      info.acknowledged,
      info.startTime,
    ]
  );
}

function _isPremium(status, expiryTime) {
  if (!expiryTime) return false;
  const stillValid = new Date(expiryTime).getTime() > Date.now();
  // Grace period e active liberam Premium; on_hold já bloqueia.
  return stillValid && (status === 'active' || status === 'grace_period');
}

function _serializar(info) {
  return {
    premium: _isPremium(info.status, info.expiryTime),
    productId: info.productId,
    status: info.status,
    expiryTime: info.expiryTime,
    autoRenewing: info.autoRenewing,
    acknowledged: info.acknowledged,
    testPurchase: info.testPurchase,
  };
}

module.exports = {
  validar,
  status,
  rtdn,
  _isPremium,
};
