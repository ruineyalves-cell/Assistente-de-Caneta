/**
 * Assinatura Premium via Stripe (web + iOS).
 *
 * Fluxo:
 *   1) User clica "Assinar Premium" no site → POST /api/stripe/checkout
 *   2) Backend cria Stripe Checkout Session → devolve URL
 *   3) User paga no Stripe (hosted page, nenhum dado financeiro toca aqui)
 *   4) Stripe dispara webhook → POST /api/stripe/webhook
 *   5) Backend atualiza stripe_status na tabela users
 *   6) GET /api/assinaturas/status já retorna premium=true (unificado)
 *
 * Segurança:
 *   - Webhook autenticado via HMAC SHA-256 (stripe-signature header)
 *   - Nenhum dado de cartão toca o backend — Stripe tokeniza tudo
 *   - stripe_customer_id vinculado ao userId (1:1)
 *   - Portal do cliente Stripe: user gerencia assinatura direto lá
 */

const db = require('../config/db');
const { logger, capturarErro } = require('../utils/logger');

let stripe = null;

function getStripe() {
  if (!stripe && process.env.STRIPE_SECRET_KEY) {
    stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  }
  return stripe;
}

function stripeConfigurado() {
  return !!(
    process.env.STRIPE_SECRET_KEY &&
    process.env.STRIPE_WEBHOOK_SECRET &&
    (process.env.STRIPE_PRICE_MONTHLY || process.env.STRIPE_PRICE_YEARLY)
  );
}

/**
 * POST /api/stripe/checkout
 * Cria Stripe Checkout Session e devolve a URL de pagamento.
 */
async function checkout(req, res, next) {
  try {
    const s = getStripe();
    if (!s) {
      return res.status(503).json({
        erro: 'Pagamento via site ainda não configurado.',
      });
    }

    const plano = req.body?.plano; // 'mensal' ou 'anual'
    const priceId =
      plano === 'anual'
        ? process.env.STRIPE_PRICE_YEARLY
        : process.env.STRIPE_PRICE_MONTHLY;

    if (!priceId) {
      return res.status(400).json({ erro: 'Plano inválido.' });
    }

    const userId = req.user.id;
    const email = req.user.email;

    // Reutiliza stripe_customer_id se o user já tem um, senão cria.
    const { rows } = await db.query(
      'SELECT stripe_customer_id FROM users WHERE id = $1',
      [userId]
    );
    let customerId = rows[0]?.stripe_customer_id;

    if (!customerId) {
      const customer = await s.customers.create({
        email,
        metadata: { recorpo_user_id: userId },
      });
      customerId = customer.id;
      await db.query(
        'UPDATE users SET stripe_customer_id = $1 WHERE id = $2',
        [customerId, userId]
      );
    }

    const siteUrl = process.env.STRIPE_SITE_URL || 'https://www.recorpo.com.br';

    const session = await s.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${siteUrl}/app?assinatura=sucesso`,
      cancel_url: `${siteUrl}/app?assinatura=cancelada`,
      subscription_data: {
        metadata: { recorpo_user_id: userId },
      },
    });

    return res.json({ url: session.url });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/stripe/webhook
 * Recebe eventos do Stripe (assinatura criada, paga, cancelada, etc.).
 * Autenticado via HMAC — NÃO usa requireAuth.
 */
async function webhook(req, res) {
  const s = getStripe();
  if (!s) return res.status(503).end();

  const sig = req.headers['stripe-signature'];
  const secret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    event = s.webhooks.constructEvent(req.body, sig, secret);
  } catch (err) {
    logger.warn({ err: err.message }, 'Stripe webhook: assinatura inválida');
    return res.status(400).json({ erro: 'Assinatura inválida.' });
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        if (session.mode === 'subscription' && session.subscription) {
          const sub = await s.subscriptions.retrieve(session.subscription);
          await _syncStripeSubscription(sub);
        }
        break;
      }

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        await _syncStripeSubscription(event.data.object);
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object;
        if (invoice.subscription) {
          const sub = await s.subscriptions.retrieve(invoice.subscription);
          await _syncStripeSubscription(sub);
        }
        break;
      }

      default:
        break;
    }

    return res.json({ received: true });
  } catch (err) {
    capturarErro(err, { context: 'stripe.webhook', eventType: event.type });
    return res.status(200).json({ received: true, error: 'processing_error' });
  }
}

/**
 * POST /api/stripe/portal
 * Redireciona o user pro portal de gerenciamento do Stripe
 * (trocar cartão, cancelar, ver faturas).
 */
async function portal(req, res, next) {
  try {
    const s = getStripe();
    if (!s) {
      return res.status(503).json({
        erro: 'Pagamento via site ainda não configurado.',
      });
    }

    const { rows } = await db.query(
      'SELECT stripe_customer_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const customerId = rows[0]?.stripe_customer_id;
    if (!customerId) {
      return res.status(404).json({
        erro: 'Você não tem assinatura ativa pelo site.',
      });
    }

    const siteUrl = process.env.STRIPE_SITE_URL || 'https://www.recorpo.com.br';

    const session = await s.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${siteUrl}/app/perfil`,
    });

    return res.json({ url: session.url });
  } catch (err) {
    next(err);
  }
}

// ─────────────────────────────────────────────────────────────

async function _syncStripeSubscription(sub) {
  const customerId = sub.customer;

  const { rows } = await db.query(
    'SELECT id FROM users WHERE stripe_customer_id = $1',
    [customerId]
  );
  if (rows.length === 0) {
    logger.warn({ customerId }, 'Stripe webhook: customer não encontrado');
    return;
  }

  const periodEnd = sub.current_period_end
    ? new Date(sub.current_period_end * 1000)
    : null;

  await db.query(
    `UPDATE users
        SET stripe_subscription_id = $1,
            stripe_status = $2,
            stripe_current_period_end = $3,
            updated_at = now()
      WHERE stripe_customer_id = $4`,
    [sub.id, sub.status, periodEnd, customerId]
  );
}

/**
 * Verifica se o user tem Premium via Stripe.
 * Usado pelo subscriptionController.status pra unificar a resposta.
 */
async function isStripePremium(userId) {
  const { rows } = await db.query(
    `SELECT stripe_status, stripe_current_period_end
       FROM users WHERE id = $1`,
    [userId]
  );
  if (rows.length === 0) return false;
  const { stripe_status, stripe_current_period_end } = rows[0];
  if (!stripe_status || !stripe_current_period_end) return false;
  const valid = new Date(stripe_current_period_end).getTime() > Date.now();
  return valid && (stripe_status === 'active' || stripe_status === 'trialing');
}

module.exports = {
  checkout,
  webhook,
  portal,
  isStripePremium,
  stripeConfigurado,
};
