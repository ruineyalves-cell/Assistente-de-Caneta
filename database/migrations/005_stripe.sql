-- ============================================================================
-- Migration 005 — Stripe subscriptions (web + iOS)
--
-- Adiciona colunas Stripe na tabela users para rastrear assinatura web.
-- Play Billing continua na tabela `subscriptions` (Android).
-- Premium = playBilling ativo OR stripe ativo.
--
-- Nenhum dado financeiro é armazenado aqui — só IDs opacos do Stripe.
-- ============================================================================

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_status TEXT CHECK (
    stripe_status IS NULL OR stripe_status IN (
      'active', 'past_due', 'canceled', 'incomplete',
      'incomplete_expired', 'trialing', 'unpaid', 'paused'
    )
  ),
  ADD COLUMN IF NOT EXISTS stripe_current_period_end TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS ix_users_stripe_customer
  ON users (stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;
